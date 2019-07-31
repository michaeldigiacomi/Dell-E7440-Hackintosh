// Instead of providing patched DSDT/SSDT, just include a single SSDT
// and do the rest of the work in config.plist

// A bit experimental, and a bit more difficult with laptops, but
// still possible.

// Note: No solution for missing IAOE here, but so far, not a problem.

DefinitionBlock("", "SSDT", 2, "hack", "_HACK", 0)
{
    External(_SB.PCI0, DeviceObj)
    External(_SB.PCI0.LPCB, DeviceObj)

    // All _OSI calls in DSDT are routed to XOSI...
    // XOSI simulates "Windows 2012" (which is Windows 8)
    // Note: According to ACPI spec, _OSI("Windows") must also return true
    //  Also, it should return true for all previous versions of Windows.
    Method(XOSI, 1)
    {
        // simulation targets
        // source: (google 'Microsoft Windows _OSI')
        //  http://download.microsoft.com/download/7/E/7/7E7662CF-CBEA-470B-A97E-CE7CE0D98DC2/WinACPI_OSI.docx
        Store(Package()
        {
            "Windows",              // generic Windows query
            "Windows 2001",         // Windows XP
            "Windows 2001 SP2",     // Windows XP SP2
            //"Windows 2001.1",     // Windows Server 2003
            //"Windows 2001.1 SP1", // Windows Server 2003 SP1
            "Windows 2006",         // Windows Vista
            "Windows 2006 SP1",     // Windows Vista SP1
            //"Windows 2006.1",     // Windows Server 2008
            "Windows 2009",         // Windows 7/Windows Server 2008 R2
            "Windows 2012",         // Windows 8/Windows Server 2012
            //"Windows 2013",       // Windows 8.1/Windows Server 2012 R2
            //"Windows 2015",       // Windows 10/Windows Server TP
        }, Local0)
        Return (Ones != Match(Local0, MEQ, Arg0, MTR, 0, 0))
    }


//
// USB related
//
    // In DSDT, native GPRW is renamed to XPRW with Clover binpatch.
    // As a result, calls to GPRW land here.
    // The purpose of this implementation is to avoid "instant wake"
    // by returning 0 in the second position (sleep state supported)
    // of the return package.
    Method(GPRW, 2)
    {
        If (0x6d == Arg0) { Return(Package() { 0x6d, 0, }) }
        External(\XPRW, MethodObj)
        Return(XPRW(Arg0, Arg1))
    }
    
    
//    
// inject properties for ECHI#1
//
    Method(_SB.PCI0.EH01._DSM, 4)
    {
        If (!Arg2) { Return (Buffer() { 0x03 } ) }
        Return (Package()
        {
            "subsystem-id", Buffer() { 0x70, 0x72, 0x00, 0x00 },
            "subsystem-vendor-id", Buffer() { 0x86, 0x80, 0x00, 0x00 },
            "AAPL,current-available", Buffer() { 0x34, 0x08, 0, 0 },
            "AAPL,current-extra", Buffer() { 0x98, 0x08, 0, 0, },
            "AAPL,current-extra-in-sleep", Buffer() { 0x40, 0x06, 0, 0, },
            "AAPL,max-port-current-in-sleep", Buffer() { 0x34, 0x08, 0, 0 },
        })
    }
    
//   
// inject properties for EHCI#2
//
    Method(_SB.PCI0.EH02._DSM, 4)
    {
        If (!Arg2) { Return (Buffer() { 0x03 } ) }
        Return (Package()
        {
            "subsystem-id", Buffer() { 0x70, 0x72, 0x00, 0x00 },
            "subsystem-vendor-id", Buffer() { 0x86, 0x80, 0x00, 0x00 },
            "AAPL,current-available", Buffer() { 0x34, 0x08, 0, 0 },
            "AAPL,current-extra", Buffer() { 0x98, 0x08, 0, 0, },
            "AAPL,current-extra-in-sleep", Buffer() { 0x40, 0x06, 0, 0, },
            "AAPL,max-port-current-in-sleep", Buffer() { 0x34, 0x08, 0, 0 },
        })
    } 


//
// Standard Injections/Fixes
//

    Scope(_SB.PCI0)
    {
        Device(IMEI)
        {
            Name (_ADR, 0x00160000)
        }

        Device(SBUS.BUS0)
        {
            Name(_CID, "smbus")
            Name(_ADR, Zero)
            Device(DVL0)
            {
                Name(_ADR, 0x57)
                Name(_CID, "diagsvault")
                Method(_DSM, 4)
                {
                    If (!Arg2) { Return (Buffer() { 0x03 } ) }
                    Return (Package() { "address", 0x57 })
                }
            }
        }
    }
   

//
// Keyboard/Trackpad
//

    External(_SB.PCI0.LPCB.PS2K, DeviceObj)
    Scope (_SB.PCI0.LPCB.PS2K)
    {
        // Select specific keyboard map in VoodooPS2Keyboard.kext
        Method(_DSM, 4)
        {
            If (!Arg2) { Return (Buffer() { 0x03 } ) }
            Return (Package()
            {
                "RM,oem-id", "DELL",
                "RM,oem-table-id", "HSW-LPT",
            })
        }
     }
       
      
}
// EOF
