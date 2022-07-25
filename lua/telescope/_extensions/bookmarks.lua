local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
  error "This plugin requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)"
end

local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local telescope_config = require("telescope.config").values
local actions = require "telescope.actions"
local entry_display = require "telescope.pickers.entry_display"

local smart_url_opener =
  require("telescope._extensions.bookmarks.actions").smart_url_opener

---@type TelescopeBookmarksState
local state = {
  os_name = vim.loop.os_uname().sysname,
  os_homedir = vim.loop.os_homedir(),
}

---@type TelescopeBookmarksConfig
local config = {}

---Prompt title.
local title = {
  brave = "Brave",
  buku = "Buku",
  chrome = "Chrome",
  chrome_beta = "Chrome",
  edge = "Edge",
  firefox = "Firefox",
  safari = "Safari",
  vivaldi = "Vivaldi",
}

-- Set the configuration state.
---@param opt_name string
---@param value any
---@param default any
local function set_config(opt_name, value, default)
  config[opt_name] = value == nil and default or value
end

---Main entrypoint for Telescope.
---@param opts table
local function bookmarks(opts)
  opts = opts or {}
  local selected_browser = config.selected_browser

  if not title[selected_browser] then
    local supported = table.concat(vim.tbl_keys(title), ", ")
    error(
      string.format("Unsupported browser: %s (%s)", selected_browser, supported)
    )
  end

  local browser =
    require("telescope._extensions.bookmarks." .. selected_browser)
  local results = browser.collect_bookmarks(state, config)
  if not results or vim.tbl_isempty(results) then
    return
  end

  local displayer = entry_display.create {
    separator = " ",
    items = config.buku_include_tags and {
      { width = 0.3 },
      { width = 0.2 },
      { remaining = true },
    } or {
      { width = 0.5 },
      { remaining = true },
    },
  }

  local function make_display(entry)
    return displayer(config.buku_include_tags and {
      entry.name,
      { entry.tags, "Tags" },
      { entry.value, "Comment" },
    } or {
      entry.name,
      { entry.value, "Comment" },
    })
  end

  pickers
    .new(opts, {
      prompt_title = "Search " .. title[selected_browser] .. " Bookmarks",
      finder = finders.new_table {
        results = results,
        entry_maker = function(entry)
          local name = (config.full_path and entry.path or entry.name) or ""
          return config.buku_include_tags
              and {
                display = make_display,
                name = name,
                value = entry.url,
                tags = entry.tags,
                ordinal = name .. " " .. entry.tags .. " " .. entry.url,
              }
            or {
              display = make_display,
              name = name,
              value = entry.url,
              ordinal = name .. " " .. entry.url,
            }
        end,
      },
      previewer = false,
      sorter = telescope_config.generic_sorter(opts),
      attach_mappings = function()
        actions.select_default:replace(smart_url_opener(config))
        return true
      end,
    })
    :find()
end

return telescope.register_extension {
  setup = function(ext_config)
    set_config("full_path", ext_config.full_path, true)
    set_config("selected_browser", ext_config.selected_browser, "brave")
    set_config("url_open_command", ext_config.url_open_command, "open")
    set_config("url_open_plugin", ext_config.url_open_plugin, nil)
    set_config("firefox_profile_name", ext_config.firefox_profile_name, nil)
    set_config("buku_include_tags", ext_config.buku_include_tags, false)
  end,
  exports = {
    bookmarks = bookmarks,
  },
  _config = _TEST and config,
}
