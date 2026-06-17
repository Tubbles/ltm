-- Dispatch's run() calls into convert/eval/seq, and those reference
-- util at call time. Eagerly require all sibling modules so their
-- globals exist before any dispatch.run() invocation.
require("util")
require("seq")
require("convert")
require("eval")
require("case")
local dispatch = require("dispatch")

describe("dispatch.parse: missing or unknown op", function()
    it("empty args returns missing-op error", function()
        local op, _, err = dispatch.parse({})
        assert.is_nil(op)
        assert.is_truthy(err:find("missing op"))
    end)

    it("nil args returns missing-op error", function()
        local op, _, err = dispatch.parse(nil)
        assert.is_nil(op)
        assert.is_truthy(err:find("missing op"))
    end)

    it("unknown op surfaces a clean error", function()
        local op, _, err = dispatch.parse({"frobnicate"})
        assert.is_nil(op)
        assert.is_truthy(err:find("unknown op"))
        assert.is_truthy(err:find("frobnicate"))
    end)
end)

describe("dispatch.parse: zero-arg ops", function()
    it("eval with no args is valid", function()
        local op, opargs, err = dispatch.parse({"eval"})
        assert.are.equal("eval", op)
        assert.are.same({}, opargs)
        assert.is_nil(err)
    end)

    it("each of the 12 converters with no args is valid", function()
        local names = {
            "dec2hex", "dec2oct", "dec2bin",
            "hex2dec", "hex2oct", "hex2bin",
            "oct2dec", "oct2hex", "oct2bin",
            "bin2dec", "bin2hex", "bin2oct",
        }
        for _, name in ipairs(names) do
            local op, opargs, err = dispatch.parse({name})
            assert.are.equal(name, op)
            assert.are.same({}, opargs)
            assert.is_nil(err)
        end
    end)

    it("upper and lower with no args are valid", function()
        for _, name in ipairs({"upper", "lower"}) do
            local op, opargs, err = dispatch.parse({name})
            assert.are.equal(name, op)
            assert.are.same({}, opargs)
            assert.is_nil(err)
        end
    end)

    it("eval with extra args is rejected", function()
        local op, _, err = dispatch.parse({"eval", "extra"})
        assert.is_nil(op)
        assert.is_truthy(err:find("takes no args"))
    end)

    it("dec2hex with extra args is rejected", function()
        local op, _, err = dispatch.parse({"dec2hex", "extra"})
        assert.is_nil(op)
        assert.is_truthy(err:find("takes no args"))
    end)

    it("upper with extra args is rejected", function()
        local op, _, err = dispatch.parse({"upper", "extra"})
        assert.is_nil(op)
        assert.is_truthy(err:find("takes no args"))
    end)
end)

describe("dispatch.parse: seq", function()
    it("with FIRST and STEP, no flag", function()
        local op, opargs, err = dispatch.parse({"seq", "0", "1"})
        assert.are.equal("seq", op)
        assert.are.equal(0, opargs.first)
        assert.are.equal(1, opargs.step)
        assert.is_nil(opargs.flag)
        assert.is_nil(err)
    end)

    it("negative FIRST", function()
        local op, opargs, err = dispatch.parse({"seq", "-5", "1"})
        assert.are.equal("seq", op)
        assert.are.equal(-5, opargs.first)
        assert.is_nil(err)
    end)

    it("non-integer STEP", function()
        local op, opargs, err = dispatch.parse({"seq", "0", "0.5"})
        assert.are.equal("seq", op)
        assert.are.equal(0.5, opargs.step)
        assert.is_nil(err)
    end)

    it("with -z flag", function()
        local op, opargs, err = dispatch.parse({"seq", "0", "1", "-z"})
        assert.are.equal("seq", op)
        assert.are.equal("z", opargs.flag)
        assert.is_nil(err)
    end)

    it("with -p flag", function()
        local op, opargs, err = dispatch.parse({"seq", "0", "1", "-p"})
        assert.are.equal("seq", op)
        assert.are.equal("p", opargs.flag)
        assert.is_nil(err)
    end)

    it("missing args", function()
        local op, _, err = dispatch.parse({"seq"})
        assert.is_nil(op)
        assert.is_truthy(err:find("missing args"))

        op, _, err = dispatch.parse({"seq", "0"})
        assert.is_nil(op)
        assert.is_truthy(err:find("missing args"))
    end)

    it("non-numeric FIRST", function()
        local op, _, err = dispatch.parse({"seq", "x", "1"})
        assert.is_nil(op)
        assert.is_truthy(err:find("FIRST is not a number"))
    end)

    it("non-numeric STEP", function()
        local op, _, err = dispatch.parse({"seq", "0", "abc"})
        assert.is_nil(op)
        assert.is_truthy(err:find("STEP is not a number"))
    end)

    it("unknown flag is rejected", function()
        local op, _, err = dispatch.parse({"seq", "0", "1", "-q"})
        assert.is_nil(op)
        assert.is_truthy(err:find("unknown flag"))
    end)

    it("too many args (both -z and -p) is rejected", function()
        local op, _, err = dispatch.parse({"seq", "0", "1", "-z", "-p"})
        assert.is_nil(op)
        assert.is_truthy(err:find("too many"))
    end)
end)

describe("dispatch.run: seq", function()
    it("produces one value per cursor regardless of inputs", function()
        local outputs, err = dispatch.run("seq",
            {first = 0, step = 1, flag = nil},
            {"ignored", "", "also ignored"},
            3)
        assert.is_nil(err)
        assert.are.same({"0", "1", "2"}, outputs)
    end)

    it("respects the padding flag", function()
        local outputs, err = dispatch.run("seq",
            {first = 0, step = 1, flag = "z"},
            {"", "", "", "", "", "", "", "", "", "", ""},
            11)
        assert.is_nil(err)
        assert.are.equal("00", outputs[1])
        assert.are.equal("10", outputs[11])
    end)
end)

describe("dispatch.run: eval", function()
    it("walks inputs element-wise", function()
        local outputs, err = dispatch.run("eval", {},
            {"1+1", "2*3", "sqrt(16)"}, 3)
        assert.is_nil(err)
        assert.are.same({"2", "6", "4"}, outputs)
    end)

    it("empty input yields nil (skip-cursor signal)", function()
        local outputs = dispatch.run("eval", {}, {"", "1+1", ""}, 3)
        assert.is_nil(outputs[1])
        assert.are.equal("2", outputs[2])
        assert.is_nil(outputs[3])
    end)

    it("eval error becomes the output text", function()
        local outputs = dispatch.run("eval", {}, {"1+", "1+1"}, 2)
        assert.is_truthy(outputs[1])
        assert.is_truthy(#outputs[1] > 0)
        assert.are.equal("2", outputs[2])
    end)
end)

describe("dispatch.run: convert ops", function()
    it("dec2hex walks inputs", function()
        local outputs = dispatch.run("dec2hex", {},
            {"255", "16", "0"}, 3)
        assert.are.same({"ff", "10", "0"}, outputs)
    end)

    it("empty input is skipped", function()
        local outputs = dispatch.run("hex2dec", {},
            {"ff", "", "ee"}, 3)
        assert.are.equal("255", outputs[1])
        assert.is_nil(outputs[2])
        assert.are.equal("238", outputs[3])
    end)

    it("invalid input yields literal nil string", function()
        local outputs = dispatch.run("hex2dec", {},
            {"ff", "xyz"}, 2)
        assert.are.equal("255", outputs[1])
        assert.are.equal("nil", outputs[2])
    end)
end)

describe("dispatch.run: case ops", function()
    it("upper walks inputs", function()
        local outputs = dispatch.run("upper", {},
            {"hello", "World", "a1-b2"}, 3)
        assert.are.same({"HELLO", "WORLD", "A1-B2"}, outputs)
    end)

    it("lower walks inputs", function()
        local outputs = dispatch.run("lower", {},
            {"HELLO", "World", "A1-B2"}, 3)
        assert.are.same({"hello", "world", "a1-b2"}, outputs)
    end)

    it("empty input is skipped", function()
        local outputs = dispatch.run("upper", {},
            {"hi", "", "bye"}, 3)
        assert.are.equal("HI", outputs[1])
        assert.is_nil(outputs[2])
        assert.are.equal("BYE", outputs[3])
    end)
end)

describe("dispatch.complete: op-name position", function()
    it("empty prefix suggests all 16 op names", function()
        local _, suggestions = dispatch.complete("ltm ", 4)
        assert.are.equal(16, #suggestions)
    end)

    it("partial prefix filters", function()
        local _, suggestions = dispatch.complete("ltm hex", 7)
        assert.are.same({"hex2bin", "hex2dec", "hex2oct"}, suggestions)
    end)

    it("partial prefix produces matching completions", function()
        local completions = dispatch.complete("ltm hex", 7)
        assert.are.same({"2bin", "2dec", "2oct"}, completions)
    end)

    it("dec prefix narrows to the three dec2 ops", function()
        local _, suggestions = dispatch.complete("ltm dec", 7)
        assert.are.same({"dec2bin", "dec2hex", "dec2oct"}, suggestions)
    end)

    it("u prefix narrows to upper", function()
        local _, suggestions = dispatch.complete("ltm u", 5)
        assert.are.same({"upper"}, suggestions)
    end)

    it("lo prefix narrows to lower", function()
        local _, suggestions = dispatch.complete("ltm lo", 6)
        assert.are.same({"lower"}, suggestions)
    end)

    it("no matches when prefix is gibberish", function()
        local completions, suggestions = dispatch.complete("ltm zzz", 7)
        assert.are.same({}, suggestions)
        assert.are.same({}, completions)
    end)

    it("an exact op name still suggests itself", function()
        local _, suggestions = dispatch.complete("ltm seq", 7)
        assert.are.same({"seq"}, suggestions)
    end)
end)

describe("dispatch.complete: seq flag position", function()
    it("dash prefix at flag position offers -p and -z", function()
        local _, suggestions = dispatch.complete("ltm seq 0 1 -", 13)
        assert.are.same({"-p", "-z"}, suggestions)
    end)

    it("empty token at flag position offers both flags", function()
        local _, suggestions = dispatch.complete("ltm seq 0 1 ", 12)
        assert.are.same({"-p", "-z"}, suggestions)
    end)

    it("partial flag prefix narrows", function()
        local _, suggestions = dispatch.complete("ltm seq 0 1 -z", 14)
        assert.are.same({"-z"}, suggestions)
    end)
end)

describe("dispatch.complete: no completion in other positions", function()
    it("at seq FIRST position", function()
        local _, suggestions = dispatch.complete("ltm seq ", 8)
        assert.are.same({}, suggestions)
    end)

    it("at seq STEP position", function()
        local _, suggestions = dispatch.complete("ltm seq 0 ", 10)
        assert.are.same({}, suggestions)
    end)

    it("after eval op", function()
        local _, suggestions = dispatch.complete("ltm eval ", 9)
        assert.are.same({}, suggestions)
    end)
end)
