import std/osproc
import std/strutils
import std/json
import std/options
import std/sequtils
import std/sugar
import std/terminal
import std/tables

# <package/one>
#     P  <test_one>
#     P  <test_two>
#
# <package/two>
#     P  <test_one>
#     X  <test_two>
#
# Packages: 2
#    Tests: 4
#   Failed: 1

let (output, exitCode) = osproc.execCmdEx("go test ./... -json")

if exitCode > 0 and not startsWith(output, "{"):
    echo "Failed to run golang tests: \n\n", output
    system.quit(exitCode)

type
    TestOutput = object
        Action: string
        Package: string
        Test: Option[string]
    TestData = tuple
        packages: int
        tests: int
        passed: int
        failed: int

let testOutputs = split(output, "\n")
    .filter(j => j != "")
    .map(j => to(parseJson(j), TestOutput))
    .filter(o => (o.Action == "pass" or o.Action == "fail") and o.Test.isSome)

var currentPackage = "-"
var testData: TestData = (0, 0, 0, 0)

for t in testOutputs:
    # echo t
    if t.Package != currentPackage:
        currentPackage = t.Package
        stdout.styledWriteLine(styleBright, "\n", currentPackage)
        testData.packages += 1

    testData.tests += 1

    case t.Action
    of "pass":
        echo "\t✅", "  ", t.Test.get()
        testData.passed += 1
    of "fail":
        stdout.styledWriteLine(fgRed, "\t❌  ", t.Test.get())
        testData.failed += 1
    else: discard

stdout.styledWriteLine(styleBright, "\n\n\tPackages: ", resetStyle, intToStr(testData.packages))
stdout.styledWriteLine(styleBright, "\t   Tests: ", resetStyle, intToStr(testData.tests))
stdout.styledWriteLine(styleBright, fgGreen, "\t  Passed: ", intToStr(testData.passed))

if testData.tests != testData.passed:
    stdout.styledWriteLine(styleBright, fgRed, "\t  Failed: ", intToStr(testData.failed))

echo "\n"
