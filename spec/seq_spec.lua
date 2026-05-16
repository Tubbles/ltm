local seq = require("lib.seq")

describe("seq.generate", function()
    it("ascending integer sequence with no padding", function()
        assert.are.same({"0", "1", "2", "3", "4"}, seq.generate(0, 1, 5, nil))
    end)

    it("descending integer sequence", function()
        assert.are.same({"5", "4", "3", "2", "1"}, seq.generate(5, -1, 5, nil))
    end)

    it("zero step repeats the first value", function()
        assert.are.same({"7", "7", "7"}, seq.generate(7, 0, 3, nil))
    end)

    it("single element", function()
        assert.are.same({"42"}, seq.generate(42, 1, 1, nil))
    end)

    it("count zero returns empty array", function()
        assert.are.same({}, seq.generate(0, 1, 0, nil))
    end)

    it("non-integer step is allowed", function()
        assert.are.same({"0", "0.5", "1", "1.5"}, seq.generate(0, 0.5, 4, nil))
    end)

    it("negative first value", function()
        assert.are.same({"-2", "-1", "0", "1"}, seq.generate(-2, 1, 4, nil))
    end)

    describe("with -z (zero pad)", function()
        it("pads to width of longest element", function()
            -- 11 elements: 0..10 means max width is 2 ("10")
            assert.are.same(
                {"00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10"},
                seq.generate(0, 1, 11, "z")
            )
        end)

        it("is sign-aware: negative values pad after the minus", function()
            assert.are.same(
                {"-2", "-1", "00", "01", "02"},
                seq.generate(-2, 1, 5, "z")
            )
        end)

        it("uses full sequence to compute width", function()
            -- values: -10, -9, ..., -1, 0
            -- max raw width is 3 from "-10"
            local result = seq.generate(-10, 1, 11, "z")
            assert.are.equal("-10", result[1])
            assert.are.equal("-09", result[2])
            assert.are.equal("-01", result[10])
            assert.are.equal("000", result[11])
        end)

        it("no padding needed when width already uniform", function()
            assert.are.same({"0", "1", "2"}, seq.generate(0, 1, 3, "z"))
        end)
    end)

    describe("with -p (space pad)", function()
        it("pads to width of longest element with spaces", function()
            assert.are.same(
                {" 0", " 1", " 2", " 3", " 4", " 5", " 6", " 7", " 8", " 9", "10"},
                seq.generate(0, 1, 11, "p")
            )
        end)

        it("negative values left-pad with spaces", function()
            assert.are.same(
                {"-2", "-1", " 0", " 1", " 2"},
                seq.generate(-2, 1, 5, "p")
            )
        end)

        it("no padding needed when width already uniform", function()
            assert.are.same({"0", "1", "2"}, seq.generate(0, 1, 3, "p"))
        end)
    end)

    it("rejects unknown flag", function()
        assert.has_error(function()
            seq.generate(0, 1, 3, "q")
        end)
    end)
end)
