import Foundation
import os.log

// Diagnostic logging for the workspace restore pipeline.
//
// These logs exist to answer "what did the restore pass actually see?" — a
// question that unit tests cannot answer, because the failures it was written
// for (a cold AX tree, a minimized or full-screen window) only reproduce
// against live apps.
//
// They are off by default in Release so end users never pay for them.
// Set FLOWSNAP_DIAG=1 in the environment to force them on in any configuration,
// which is what you want when reproducing a report from a machine you cannot
// rebuild on:
//
//     FLOWSNAP_DIAG=1 open -a FlowSnap
//     log stream --predicate 'subsystem == "com.flowsnap.diag"'
//
// The gate is evaluated once at first use, so in Release the cost is a single
// cached Bool rather than an environment lookup per line.
private let diagEnabled: Bool = {
    #if DEBUG
    return true
    #else
    return ProcessInfo.processInfo.environment["FLOWSNAP_DIAG"] == "1"
    #endif
}()

private let flowsnapDiagLog = OSLog(subsystem: "com.flowsnap.diag", category: "restore")

/// Emits a restore-pipeline diagnostic line. A no-op in Release unless
/// `FLOWSNAP_DIAG=1` is set in the environment.
public func diagPrint(_ message: String) {
    guard diagEnabled else { return }
    os_log("%{public}s", log: flowsnapDiagLog, type: .default, message)
}
