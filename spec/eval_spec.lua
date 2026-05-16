require("util")  -- sets _G.util; eval references util at call time
local eval = require("eval")

describe("eval: pure Lua arithmetic", function()
    it("integer addition", function()
        assert.are.equal("4", (eval.eval("1+3")))
    end)

    it("subtraction with negative result", function()
        assert.are.equal("-5", (eval.eval("3-8")))
    end)

    it("multiplication", function()
        assert.are.equal("42", (eval.eval("6 * 7")))
    end)

    it("true division", function()
        assert.are.equal("0.5", (eval.eval("1/2")))
    end)

    it("modulo", function()
        assert.are.equal("1", (eval.eval("7 % 3")))
    end)

    it("exponent via the caret operator", function()
        assert.are.equal("256", (eval.eval("2^8")))
    end)

    it("parentheses for grouping", function()
        assert.are.equal("20", (eval.eval("(2+3) * 4")))
    end)
end)

describe("eval: math flatten", function()
    it("sqrt is reachable as a bare global", function()
        assert.are.equal("4", (eval.eval("sqrt(16)")))
    end)

    it("floor is reachable as a bare global", function()
        assert.are.equal("3", (eval.eval("floor(3.7)")))
    end)

    it("ceil is reachable as a bare global", function()
        assert.are.equal("4", (eval.eval("ceil(3.2)")))
    end)

    it("abs is reachable as a bare global", function()
        assert.are.equal("5", (eval.eval("abs(-5)")))
    end)

    it("pi is reachable as a bare global constant", function()
        local result = eval.eval("pi")
        assert.is_truthy(result:find("^3%.14"))
    end)

    it("max and min are bare globals", function()
        assert.are.equal("9", (eval.eval("max(3, 9, 5)")))
        assert.are.equal("3", (eval.eval("min(3, 9, 5)")))
    end)
end)

describe("eval: _G fallback for non-math globals", function()
    it("tostring is reachable", function()
        assert.are.equal("123", (eval.eval("tostring(123)")))
    end)

    it("tonumber is reachable", function()
        assert.are.equal("255", (eval.eval("tonumber('ff', 16)")))
    end)

    it("string namespace is reachable", function()
        assert.are.equal("ff", (eval.eval("string.format('%x', 255)")))
    end)

    it("type is reachable", function()
        assert.are.equal("number", (eval.eval("type(1)")))
    end)

    it("math namespace itself is reachable", function()
        local result = eval.eval("math.pi")
        assert.is_truthy(result:find("^3%.14"))
    end)
end)

describe("eval: error handling", function()
    it("parse error returns nil and a cleaned message", function()
        local result, err = eval.eval("1 +")
        assert.is_nil(result)
        assert.is_truthy(err)
        -- err should not contain the [string "..."] prefix
        assert.is_nil(err:find('%[string'))
    end)

    it("runtime error returns nil and a cleaned message", function()
        local result, err = eval.eval("notavar + 1")
        assert.is_nil(result)
        assert.is_truthy(err)
        assert.is_nil(err:find('%[string'))
        assert.is_truthy(err:find("nil"))
    end)

    it("explicit error() call surfaces the message", function()
        local result, err = eval.eval("error('boom')")
        assert.is_nil(result)
        assert.is_truthy(err)
        assert.is_truthy(err:find("boom"))
    end)
end)

describe("eval: float corner cases", function()
    it("division by zero yields inf (not an error)", function()
        local result, err = eval.eval("1/0")
        assert.is_nil(err)
        assert.is_truthy(result == "inf" or result == "1.#INF")
    end)

    it("negative division by zero yields -inf", function()
        local result, err = eval.eval("-1/0")
        assert.is_nil(err)
        assert.is_truthy(result == "-inf" or result == "-1.#INF")
    end)

    it("zero divided by zero yields nan", function()
        local result, err = eval.eval("0/0")
        assert.is_nil(err)
        assert.is_truthy(result == "nan" or result == "-nan" or result == "-1.#IND")
    end)
end)

describe("eval: scope isolation", function()
    it("assignments inside an expression do not leak to _G", function()
        eval.eval("foo = 99")
        -- _G.foo should still be nil after the eval
        assert.is_nil(_G.foo)
    end)
end)

describe("eval: collision guard via util.flatten", function()
    it("flatten itself raises on a second flatten with overlapping keys", function()
        local util = require("util")
        local env = {}
        util.flatten(env, {abs = "first"})
        assert.has_error(function()
            util.flatten(env, {abs = "second"})
        end)
    end)
end)
