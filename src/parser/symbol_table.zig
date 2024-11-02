// This file is a part of Pytongue.
//
// Copyright (C) 2024 Oleksandr Korzh
//
// Pytongue is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Pytongue is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Pytongue. If not, see <https://www.gnu.org/licenses/>.

const std = @import("std");
const lsp_specs = @import("lsp_specs");
const Position = lsp_specs.lsp_types.Position;
const SymbolKind = lsp_specs.enums.SymbolKind;
const Range = lsp_specs.lsp_types.Range;

pub const Symbol = struct {
    name: []const u8,
    kind: SymbolKind,
    position: Position,
    scope: ?*Scope,
    docstring: ?[]const u8,
    references: std.ArrayList(Position), // temporary, might switch to another solution later (map)

    // TODO create init
};

pub const Scope = struct {
    parent: ?*Scope,
    symbols: std.StringHashMap(Symbol),
    children: std.ArrayList(*Scope),
    allocator: std.mem.Allocator,
    uri: []const u8,
    range: ?Range,
    pub fn init(allocator: std.mem.Allocator, parent: ?*Scope, uri: []const u8, range: ?Range) Scope {
        return Scope{
            .parent = parent,
            .symbols = std.StringHashMap(Symbol).init(allocator),
            .children = std.ArrayList(*Scope).init(allocator),
            .allocator = allocator,
            .uri = uri,
            .range = range,
        };
    }
    pub fn deinit(self: *Scope) void {
        for (self.children.items) |child| {
            child.deinit();
            self.allocator.destroy(child);
        }
        self.children.deinit();
        var i = self.symbols.iterator();
        while (i.next()) |symbol| {
            // self.allocator.free(symbol.key_ptr.*);
            symbol.value_ptr.references.deinit();
        }
        self.symbols.deinit();
    }

    pub fn addSymbol(self: *Scope, symbol: Symbol) !void {
        // assuming symbol.scope is already set
        try self.symbols.put(symbol.name, symbol);
    }

    pub fn getSymbol(self: *Scope, name: []const u8) ?Symbol {
        return self.symbols.get(name);
    }

    pub fn addChildScope(self: *Scope, child_scope: *Scope) !void {
        child_scope.parent = self;
        try self.children.append(child_scope);
    }

    pub fn findInnermostScope(self: *Scope, position: Position) ?*Scope {
        // no range for scopes bigger than file
        if (self.range == null or (self.range != null and position.inRange(self.range.?))) {
            for (self.children.items) |child| {
                const innermost = child.findInnermostScope(position);
                if (innermost != null) {
                    return innermost;
                }
            }
            return self;
        }
        return null;
    }
};

pub fn CreateScope(allocator: std.mem.Allocator, parent: ?*Scope, uri: []const u8, range: ?Range) !*Scope {
    const scope = try allocator.create(Scope);
    scope.* = .{
        .parent = parent,
        .symbols = std.StringHashMap(Symbol).init(allocator),
        .children = std.ArrayList(*Scope).init(allocator),
        .allocator = allocator,
        .uri = uri,
        .range = range,
    };
    return scope;
}

pub const SymbolTable = struct {
    rootScope: Scope,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, root_uri: []const u8) SymbolTable {
        return SymbolTable{
            .rootScope = Scope.init(allocator, null, root_uri, null),
            .allocator = allocator,
        };
    }
    pub fn deinit(self: *SymbolTable) void {
        self.rootScope.deinit();
    }

    pub fn findInnermostScope(self: *SymbolTable, position: Position) ?*Scope {
        return self.rootScope.findInnermostScope(position);
    }
};
