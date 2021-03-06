local test_env = require("spec.util.test_env")
local lfs = require("lfs")
local run = test_env.run
local testing_paths = test_env.testing_paths

test_env.unload_luarocks()

local extra_rocks = {
   "/abelhas-1.1-1.src.rock",
   "/copas-2.0.1-1.src.rock",
   "/coxpcall-1.16.0-1.src.rock",
   "/coxpcall-1.16.0-1.rockspec"
}

describe("luarocks remove #integration", function()

   before_each(function()
      test_env.setup_specs(extra_rocks)
   end)

   describe("basic tests", function()
      it("with no flags/arguments", function()
         assert.is_false(run.luarocks_bool("remove"))
      end)

      it("invalid rock", function()
         assert.is_false(run.luarocks_bool("remove invalid.rock"))
      end)
      
      it("missing rock", function()
         assert.is_false(run.luarocks_bool("remove missing_rock"))
      end)
      
      it("invalid argument", function()
         assert.is_false(run.luarocks_bool("remove luacov --deps-mode"))
      end)

      it("built abelhas", function()
         assert.is_true(run.luarocks_bool("build abelhas 1.1"))
         assert.is.truthy(lfs.attributes(testing_paths.testing_sys_rocks .. "/abelhas"))
         assert.is_true(run.luarocks_bool("remove abelhas 1.1"))
         assert.is.falsy(lfs.attributes(testing_paths.testing_sys_rocks .. "/abelhas"))
      end)

      it("built abelhas with uppercase name", function()
         assert.is_true(run.luarocks_bool("build abelhas 1.1"))
         assert.is.truthy(lfs.attributes(testing_paths.testing_sys_rocks .. "/abelhas"))
         assert.is_true(run.luarocks_bool("remove Abelhas 1.1"))
         assert.is.falsy(lfs.attributes(testing_paths.testing_sys_rocks .. "/abelhas"))
      end)
   end)

   describe("more complex tests", function()
      before_each(function()
         assert.is.truthy(test_env.need_rock("coxpcall"))
      end)

      it("fail, break dependencies", function()
         assert.is.truthy(lfs.attributes(testing_paths.testing_sys_rocks .. "/coxpcall"))
         assert.is_true(run.luarocks_bool("build copas"))

         assert.is_false(run.luarocks_bool("remove coxpcall"))
         assert.is.truthy(lfs.attributes(testing_paths.testing_sys_rocks .. "/coxpcall"))
      end)
      
      it("force", function()
         assert.is.truthy(lfs.attributes(testing_paths.testing_sys_rocks .. "/coxpcall"))
         assert.is_true(run.luarocks_bool("build copas"))

         local output = run.luarocks("remove --force coxpcall")
         assert.is.falsy(lfs.attributes(testing_paths.testing_sys_rocks .. "/coxpcall"))
         assert.is.truthy(output:find("Checking stability of dependencies"))
      end)
      
      it("force fast", function()
         assert.is.truthy(lfs.attributes(testing_paths.testing_sys_rocks .. "/coxpcall"))
         assert.is_true(run.luarocks_bool("build copas"))

         local output = run.luarocks("remove --force-fast coxpcall")
         assert.is.falsy(lfs.attributes(testing_paths.testing_sys_rocks .. "/coxpcall"))
         assert.is.falsy(output:find("Checking stability of dependencies"))
      end)
   end)

   it("#admin remove #ssh", function()
      assert.is_true(run.luarocks_admin_bool("--server=testing remove coxpcall-1.16.0-1.src.rock"))
   end)
   
   it("#admin remove missing", function()
      assert.is_false(run.luarocks_admin_bool("--server=testing remove"))
   end)
end)
