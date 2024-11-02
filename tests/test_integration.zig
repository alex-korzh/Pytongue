const std = @import("std");

const testing = std.testing;

const parser = @import("parser");
const TreeSitter = parser.TreeSitter;
const tree_sitter_python = parser.tree_sitter_python;
const Workspace = parser.Workspace;

test "parse-python-file" {
    const allocator = testing.allocator;

    const p = TreeSitter.ts_parser_new().?;

    _ = TreeSitter.ts_parser_set_language(p, tree_sitter_python());
    // FIXME
    var workspace = Workspace.init(
        "/home/alex/Documents/code/zig/pytongue",
        "/home/alex/Documents/code/zig/pytongue/.venv/bin/python",
        p,
        allocator,
    );
    const cwd = try std.fs.cwd().realpathAlloc(allocator, ".");
    const filePath = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ cwd, "tests/assets/main.py" });
    defer {
        TreeSitter.ts_parser_delete(p);
        workspace.deinit();
        allocator.free(cwd);
        allocator.free(filePath);
    }
    _ = try workspace.parseFile(filePath, false);
}
