//
//  VMInstaller.swift
//  MacBox
//
//  Created by Tom on 2025/06/28.
//

import Foundation
import Virtualization

public class VMInstaller {
    private var installer: VZMacOSInstaller
    private var installationObserver: NSKeyValueObservation?
    private var virtualMachine: VZVirtualMachine!
    private var vmResponder: MacOsVirtualMachineDelegate?
    
    
    public init() {}
    
    public func install(vmConfiguration: VMCustomization) throws {
        
    }
}
