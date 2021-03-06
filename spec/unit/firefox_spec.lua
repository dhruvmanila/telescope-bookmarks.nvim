local utils = require "telescope._extensions.bookmarks.utils"

local profiles = {
  -- There was some parse error, so an empty table was returned.
  parse_failure = {},

  -- Default test profile config.
  default_profile = {
    Profile0 = {
      Name = "default-release",
      IsRelative = 1,
      Path = "Profiles/default-release",
      Default = 1,
    },
    Profile1 = {
      Name = "dev-edition-default",
      -- This profile contains absolute path to the profile directory.
      IsRelative = 0,
      Path = "Profiles/dev-edition-default",
    },
  },

  -- There is no default profile in this config.
  no_default_profile = {
    Profile0 = {
      Name = "default-release",
      IsRelative = 1,
      Path = "Profiles/default-release",
    },
  },
}

describe("firefox", function()
  before_each(function()
    stub(utils, "warn")
  end)

  after_each(function()
    utils.warn:revert()
  end)

  -- Insulate this block to avoid `ini.load` being overridden in other blocks.
  insulate("get_profile_dir", function()
    local match = require "luassert.match"
    local ini = require "telescope._extensions.bookmarks.parser.ini"
    local firefox = require "telescope._extensions.bookmarks.firefox"

    -- Override the original function to load the data directly from the
    -- "profiles" table defined above. The first part of the path is used as
    -- the key which is the `os_homedir` in the state table.
    ini.load = function(path)
      local key = vim.split(path, "/")[1]
      return profiles[key]
    end

    it("should warn if OS not supported", function()
      local profile_dir = firefox._get_profile_dir({ os_name = "random" }, {})

      assert.is_nil(profile_dir)
      assert.stub(utils.warn).was_called()
      assert
        .stub(utils.warn)
        .was_called_with(match.matches "Unsupported OS for firefox browser")
    end)

    it("should warn if failed to parse profiles.ini", function()
      local profile_dir = firefox._get_profile_dir({
        os_name = "Darwin",
        os_homedir = "parse_failure",
      }, {})

      assert.is_nil(profile_dir)
      assert.stub(utils.warn).was_called()
      assert
        .stub(utils.warn)
        .was_called_with(match.matches "Unable to parse firefox profiles config file")
    end)

    it("should return default profile directory", function()
      local profile_dir = firefox._get_profile_dir({
        os_name = "Darwin",
        os_homedir = "default_profile",
      }, {})

      assert.is_not_nil(profile_dir)
      assert.is_true(vim.endswith(profile_dir, "Profiles/default-release"))
    end)

    it("should return user given profile directory", function()
      local profile_dir = firefox._get_profile_dir(
        { os_name = "Darwin", os_homedir = "default_profile" },
        { firefox_profile_name = "dev-edition-default" }
      )

      assert.is_not_nil(profile_dir)
      -- Also testing if the `IsRelative` key is being considered or not.
      assert.are_equal(profile_dir, "Profiles/dev-edition-default")
    end)

    it("should warn if user given profile does not exist", function()
      local profile_dir = firefox._get_profile_dir(
        { os_name = "Darwin", os_homedir = "default_profile" },
        { firefox_profile_name = "random" }
      )

      assert.is_nil(profile_dir)
      assert.stub(utils.warn).was_called()
      assert
        .stub(utils.warn)
        .was_called_with(match.matches "Given firefox profile does not exist")
    end)

    it("should warn if unable to deduce default profile", function()
      local profile_dir = firefox._get_profile_dir({
        os_name = "Darwin",
        os_homedir = "no_default_profile",
      }, {})

      assert.is_nil(profile_dir)
      assert.stub(utils.warn).was_called()
      assert
        .stub(utils.warn)
        .was_called_with(match.matches "Unable to deduce the default firefox profile name")
    end)
  end)

  describe("collect_bookmarks", function()
    local match = require "luassert.match"
    local firefox = require "telescope._extensions.bookmarks.firefox"

    it("should return nil if unable to get profile directory", function()
      local bookmarks = firefox.collect_bookmarks(
        { os_name = "Darwin", os_homedir = "spec/fixtures" },
        { firefox_profile_name = "random" }
      )

      assert.is_nil(bookmarks)
      assert.stub(utils.warn).was_called()
      assert
        .stub(utils.warn)
        .was_called_with(match.matches "Given firefox profile does not exist")
    end)

    it("should parse bookmarks data", function()
      local bookmarks = firefox.collect_bookmarks({
        os_name = "Darwin",
        os_homedir = "spec/fixtures",
      }, {})

      assert.are.same(bookmarks, {
        {
          name = "GitHub",
          path = "GitHub",
          url = "https://github.com/",
        },
        {
          name = "Google",
          path = "search/Google",
          url = "https://google.com/",
        },
        {
          name = "DuckDuckGo",
          path = "search/nested/DuckDuckGo",
          url = "https://duckduckgo.com/",
        },
      })
    end)

    it("should parse bookmarks data for given firefox profile", function()
      local bookmarks = firefox.collect_bookmarks(
        { os_name = "Darwin", os_homedir = "spec/fixtures" },
        { firefox_profile_name = "dev-edition-default" }
      )

      assert.are.same(bookmarks, {
        {
          name = "GitHub",
          path = "GitHub",
          url = "https://github.com/",
        },
        {
          name = "Google",
          path = "search/Google",
          url = "https://google.com/",
        },
        {
          name = "DuckDuckGo",
          path = "search/nested/DuckDuckGo",
          url = "https://duckduckgo.com/",
        },
      })
    end)
  end)
end)
