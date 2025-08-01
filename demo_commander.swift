#!/usr/bin/env swift

import Foundation

// Demo the SubagentCommander system
let commander = SubagentCommander()

print("=== SUBAGENT COMMANDER DEMONSTRATION ===")
print()

// Get assignment for MeshChatView (Critical Priority)
let meshChatAssignment = commander.assignWork(for: .meshChat)
print("📱 MESH CHAT ASSIGNMENT:")
print("Priority: \(meshChatAssignment.priority.rawValue)")
print("Complexity: \(meshChatAssignment.estimatedComplexity.rawValue)")
print("Components: \(meshChatAssignment.requiredComponents.count)")
print()

// Generate the actual prompt for a subagent
let meshChatPrompt = commander.generateSubagentPrompt(for: meshChatAssignment)
print("🤖 SUBAGENT PROMPT PREVIEW (First 500 chars):")
print(String(meshChatPrompt.prefix(500)) + "...")
print()

// Show all assignments
let allAssignments = SubagentCommander.createViewAssignments()
print("📋 ALL VIEW ASSIGNMENTS:")
for assignment in allAssignments.sorted(by: { a, b in
    if a.priority.rawValue != b.priority.rawValue {
        return a.priority.rawValue < b.priority.rawValue
    }
    return a.viewTarget.rawValue < b.viewTarget.rawValue
}) {
    print("• \(assignment.viewTarget.rawValue): \(assignment.priority.rawValue) priority, \(assignment.estimatedComplexity.rawValue) complexity")
}
print()
print("✅ SubagentCommander system ready for deployment")