import Testing
@testable import SyncMyPod

struct SysInfoExtendedParserTests {
    /// Mirrors real 7G firmware output, including the invalid `<key>` inside `<array>`.
    private let firmwareXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <plist version="1.0">
    <dict>
    <key>BuildID</key>
    <string>9.0.4</string>
    <key>FamilyID</key>
    <integer>11</integer>
    <key>FireWireGUID</key>
    <string>000A2700ABCDEF01</string>
    <key>ImageSpecifications</key>
    <array>
    <key>1067</key>
    <dict>
    <key>FormatId</key>
    <integer>1067</integer>
    </dict>
    </array>
    <key>SerialNumber</key>
    <string>8K2000009ZU</string>
    <key>VisibleBuildID</key>
    <string>2.0.4</string>
    </dict>
    </plist>
    """

    @Test func extractsScalarsFromMalformedFirmwarePlist() {
        let values = SysInfoExtendedParser.scalarValues(in: firmwareXML)
        #expect(values["VisibleBuildID"] == "2.0.4")
        #expect(values["SerialNumber"] == "8K2000009ZU")
        #expect(values["FireWireGUID"] == "000A2700ABCDEF01")
        #expect(values["FamilyID"] == "11")
    }

    @Test func mergeFillsOnlyMissingFields() {
        var sysInfo = IPodSysInfo()
        sysInfo.firmwareVersion = "1.1.2"
        sysInfo.mergeExtended(SysInfoExtendedParser.scalarValues(in: firmwareXML))
        #expect(sysInfo.firmwareVersion == "1.1.2")
        #expect(sysInfo.serialNumber == "8K2000009ZU")
        #expect(sysInfo.firewireGUID == "000A2700ABCDEF01")
        #expect(!sysInfo.isMissingExtendedFields)
    }
}
