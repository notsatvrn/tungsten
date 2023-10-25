const std = @import("std");

const Allocator = std.mem.Allocator;
const Token = @import("lexer.zig").Token;

// TREES -> NODES
pub const RootTree = std.ArrayList(RootNode);

pub const RootNode = union(enum) {
    function: Function,
    constant: Constant,
};

pub const BlockTree = std.ArrayList(BlockNode);

pub const BlockNode = union(enum) {
    call: Call,
    builtin_call: BuiltinCall,
    constant: Constant,
    variable: Variable,
    assignment: Assignment,
};

pub const TreeKind = enum { root, block };

pub const Tree = union(TreeKind) {
    root: RootTree,
    block: RootNode,
};

// EXPRESSIONS
pub const Comparator = enum {
    eq,
    ne,
    gt,
    lt,
    gt_eq,
    lt_eq,
};

pub const BooleanOperator = enum {
    l_and,
    l_or,

    const Self = @This();

    pub inline fn fromDouble(symbol: u8) ?Self {
        if (symbol == '&') return Self.l_and;
        if (symbol == '|') return Self.l_or;
        return null;
    }
};

pub const Operator = enum {
    sum,
    sub,
    div,
    mul,
    mod,
    bw_ls,
    bw_lrs,
    bw_ars,
    bw_and,
    bw_or,
    bw_not,
    l_not,
    xor,

    const Self = @This();

    pub inline fn fromSymbol(symbol: u8) ?Self {
        return switch (symbol) {
            '+' => Self.sum,
            '-' => Self.sub,
            '/' => Self.div,
            '*' => Self.mul,
            '%' => Self.mod,
            '&' => Self.bw_and,
            '|' => Self.bw_or,
            '~' => Self.bw_not,
            '!' => Self.l_not,
            '^' => Self.xor,
            else => null,
        };
    }
};

// EXPRESSIONS
pub const LiteralOperand = union(enum) {
    false,
    true,
    null,
    undefined,
    char: u8,
    string: []const u8,
    uint: u128,
    int: i128,
    float: f128,

    const Self = @This();

    pub inline fn fromToken(token: Token) ?Self {
        return switch (token) {
            Token.value => |value| {
                if (std.mem.eql(u8, value, "false")) return Self.false;
                if (std.mem.eql(u8, value, "true")) return Self.true;
                if (std.mem.eql(u8, value, "null")) return Self.null;
                if (std.mem.eql(u8, value, "undefined")) return Self.undefined;
                unreachable;
            },
            Token.char => |char| .{ .char = char },
            Token.string => |string| .{ .string = string },
            Token.uint => |uint| .{ .uint = uint },
            Token.int => |int| .{ .int = int },
            Token.float => |float| .{ .float = float },
            else => null,
        };
    }
};

pub const NonLiteralOperand = union(enum) {
    identifier: []const u8,
    field_access: FieldAccess,
    call: Call,
    builtin_call: BuiltinCall,

    const Self = @This();

    pub inline fn fromToken(token: Token) ?Self {
        return if (token == Token.identifier) .{ .identifier = token.identifier } else null;
    }
};

pub const Operand = union(enum) {
    literal: LiteralOperand,
    non_literal: NonLiteralOperand,

    const Self = @This();

    pub fn fromToken(token: Token) ?Self {
        if (LiteralOperand.fromToken(token)) |e| {
            return .{ .literal = e };
        } else if (NonLiteralOperand.fromToken(token)) |e| {
            return .{ .non_literal = e };
        }

        return null;
    }
};

// EXPRESSION CHAINS
pub const ExpressionItem = union(enum) {
    operand: Operand,
    expression: Expression,
    comparator: Comparator,
    boolean_operator: BooleanOperator,
    operator: Operator,
};

pub const Expression = std.ArrayList(ExpressionItem);

// TYPES
pub const PointerType = struct {
    constant: bool = false,
    slice: bool = false,
    expression: NonLiteralOperand = undefined,
};

pub const ArrayType = struct {
    size: usize = 0,
    expression: NonLiteralOperand = undefined,
};

pub const Type = union(enum) {
    single: NonLiteralOperand,
    ptr: PointerType,
    array: ArrayType,
};

// CONSTANT DECLARATION
pub const Constant = struct {
    name: []const u8 = "",
    typ: Type = undefined,
    val: Expression = undefined,
    public: bool = false,
};

// VARIABLE DECLARATION
pub const Variable = struct {
    name: []const u8 = "",
    typ: ?Type = null,
    val: ?Expression = null,
    mutable: bool = false,
    public: bool = false,
};

// VARIABLE ASSIGNMENT
pub const Assignment = struct {
    variable: NonLiteralOperand = undefined,
    operator: ?Operator = null,
    expression: Expression = undefined,
};

pub const IndexAccess = struct {
    object: *Operand = undefined,
    index: Expression = undefined,
};

// FUNCTIONS
pub const Parameter = struct {
    name: []const u8 = "",
    typ: Type = undefined,
};

pub const Parameters = std.ArrayList(Parameter);

pub const Function = struct {
    name: []const u8 = "",
    params: Parameters = undefined,
    typ: Type = undefined,
    body: Tree = undefined,
    public: bool = false,
};

// FUNCTION CALLS
pub const Call = struct {
    callee: *Operand = undefined,
    arguments: std.ArrayList(Expression) = undefined,
};

pub const BuiltinCall = struct {
    callee: []const u8 = "",
    arguments: std.ArrayList(Expression) = undefined,
};

// OBJECTS - FIELDS
pub const FieldAccess = struct {
    object: *Operand = undefined,
    field: []const u8 = "",
};

pub const Field = struct {
    name: []const u8 = "",
    typ: Type = undefined,
    default: ?*Expression = null,
    public: bool = false,
};

// OBJECTS - STRUCT
pub const Struct = struct {
    fields: std.ArrayList(Field),
    methods: std.ArrayList(Function),
};
