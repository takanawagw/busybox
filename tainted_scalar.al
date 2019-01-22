DEFINE-CHECKER TAINTED_INT = {

  LET signed_scalar_type = has_type("long long") OR
                           has_type("long") OR
                           has_type("int") OR
                           has_type("short") OR
                           has_type("char");

  LET unsigned_scalar_type = has_type("unsigned long long") OR
                             has_type("unsigned long") OR
                             has_type("unsigned int") OR
                             has_type("unsigned short") OR
                             has_type("unsigned char");

  LET scalar_type = signed_scalar_type OR unsigned_scalar_type;

  LET scalar_return_call = is_node("CallExpr") AND scalar_type;
  LET assign_returned_scalar = is_node("DeclStmt") AND
                               scalar_return_call HOLDS-NEXT;

  LET comp_op_gte = is_binop_with_kind("GT") OR
                    is_binop_with_kind("GE");
  LET comp_op_lte = is_binop_with_kind("LT") OR
                    is_binop_with_kind("LE");

  LET sanitize_op = (comp_op_lte AND unsigned_scalar_type HOLDS-NEXT) OR
                    (is_binop_with_kind("LAnd") AND
                     comp_op_gte HOLDS-NEXT AND
                     comp_op_lte HOLDS-NEXT);

  LET sanitize_scalar = is_node("IfStmt") AND sanitize_op HOLDS-NEXT;

  LET need_bounds_check = is_node("ForStmt") OR
                          (is_node("CallExpr") AND
                           call_function(REGEXP("alloc"))) OR
                          is_node("ArraySubscriptExpr");

  SET report_when = NOT sanitize_scalar HOLDS-EVENTUALLY AND
                    assign_returned_scalar HOLDS-EVENTUALLY AND
                    need_bounds_check HOLDS-EVENTUALLY;

  SET message = "Found TAINTED_SCALAR";
  SET suggestion = "Signed scalars must be upper- and lower-bounds checked. Unsigned integers need only an upper-bounds check.";
  SET severity = "ERROR";
};
