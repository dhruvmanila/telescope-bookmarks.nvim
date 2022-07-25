local buku = require "telescope._extensions.bookmarks.buku"

describe("buku", function()
  after_each(function()
    -- Reset the environment variables.
    vim.env.XDG_DATA_HOME = nil
    vim.env.APPDATA = nil
  end)

  describe("get_default_dbdir", function()
    it("when XDG_DATA_HOME is available", function()
      vim.env.XDG_DATA_HOME = "."
      local dbdir = buku._get_default_dbdir()
      assert.are.equal(dbdir, "./buku")
    end)

    it("when XDG_DATA_HOME not available on Linux", function()
      local dbdir = buku._get_default_dbdir {
        os_name = "Linux",
        os_homedir = ".",
      }
      assert.are.equal(dbdir, "./.local/share/buku")
    end)

    it("when APPDATA is available on windows", function()
      vim.env.APPDATA = "."
      local dbdir = buku._get_default_dbdir { os_name = "Windows_NT" }
      assert.are.equal(dbdir, "./buku")
    end)

    it("when APPDATA is not available on windows", function()
      local dbdir = buku._get_default_dbdir { os_name = "Windows_NT" }
      assert.are.equal(dbdir, vim.loop.cwd())
    end)
  end)

  describe("collect_bookmarks", function()
    it("should parse bookmarks data", function()
      vim.env.XDG_DATA_HOME = "spec/fixtures"
      assert.are.same(buku.collect_bookmarks(), {
        {
          name = "GitHub",
          path = "GitHub",
          url = "https://github.com/",
          tags = "coding",
        },
        {
          name = "Google",
          path = "Google",
          url = "https://google.com/",
          tags = "search",
        },
      })
    end)
  end)
end)
