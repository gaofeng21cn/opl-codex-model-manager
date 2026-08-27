import Foundation
import XCTest
@testable import CodexModelManager

final class CustomModelEditorTests: XCTestCase {
    func testAddingClonesTemplateAndOverridesEditableFields() throws {
        let source = try JSONSerialization.data(withJSONObject: [
            "models": [[
                "slug": "template-model",
                "display_name": "Template",
                "description": "Template description",
                "context_window": 100_000,
                "max_context_window": 100_000,
                "input_modalities": ["text"],
                "supports_image_detail_original": false,
                "priority": 50,
                "wire_api": "responses",
                "supports_tools": true
            ]]
        ])
        var draft = NewModelDraft()
        draft.slug = " Vendor-Vision "
        draft.displayName = " Vendor Vision "
        draft.description = " Hosted multimodal model "
        draft.templateSlug = "template-model"
        draft.contextWindow = 262_144
        draft.supportsImage = true
        draft.supportsOriginalImageDetail = true

        let updated = try CustomModelEditor.adding(
            draft: draft,
            to: source,
            existingSlugs: ["template-model"]
        )
        let root = try XCTUnwrap(
            JSONSerialization.jsonObject(with: updated) as? [String: Any]
        )
        let models = try XCTUnwrap(root["models"] as? [[String: Any]])
        let added = try XCTUnwrap(models.last)

        XCTAssertEqual(models.count, 2)
        XCTAssertEqual(added["slug"] as? String, "vendor-vision")
        XCTAssertEqual(added["display_name"] as? String, "Vendor Vision")
        XCTAssertEqual(added["description"] as? String, "Hosted multimodal model")
        XCTAssertEqual(added["context_window"] as? Int, 262_144)
        XCTAssertEqual(added["max_context_window"] as? Int, 262_144)
        XCTAssertEqual(added["input_modalities"] as? [String], ["text", "image"])
        XCTAssertEqual(added["supports_image_detail_original"] as? Bool, true)
        XCTAssertEqual(added["priority"] as? Int, 51)
        XCTAssertEqual(added["wire_api"] as? String, "responses")
        XCTAssertEqual(added["supports_tools"] as? Bool, true)
    }

    func testAddingRejectsDuplicateAndInvalidSlugs() throws {
        let source = try JSONSerialization.data(withJSONObject: [
            "models": [[
                "slug": "template-model",
                "display_name": "Template",
                "description": "Template description",
                "priority": 1
            ]]
        ])
        var draft = NewModelDraft()
        draft.slug = "template-model"
        draft.displayName = "Duplicate"
        draft.description = "Duplicate model"
        draft.templateSlug = "template-model"

        XCTAssertThrowsError(
            try CustomModelEditor.adding(
                draft: draft,
                to: source,
                existingSlugs: ["template-model"]
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("已存在"))
        }

        draft.slug = "Invalid Slug"
        XCTAssertThrowsError(
            try CustomModelEditor.adding(
                draft: draft,
                to: source,
                existingSlugs: []
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("slug"))
        }
    }
}
