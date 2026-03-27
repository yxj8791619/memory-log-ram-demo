extends RefCounted
class_name TestAssert

static func start(case_name: String) -> void:
    print("[TEST START] %s" % case_name)


static func info(message: String) -> void:
    print("[TEST INFO] %s" % message)


static func pass_case(case_name: String) -> void:
    print("[TEST PASS] %s" % case_name)


static func fail_case(case_name: String, reason: String) -> void:
    print("[TEST FAIL] %s: %s" % [case_name, reason])


static func blocked_case(case_name: String, reason: String) -> void:
    print("[TEST BLOCKED] %s: %s" % [case_name, reason])


static func expect_true(value: bool, case_name: String, reason: String) -> bool:
    if value:
        return true
    fail_case(case_name, reason)
    return false


static func expect_equal(actual, expected, case_name: String, reason: String) -> bool:
    if actual == expected:
        return true
    fail_case(case_name, "%s (actual=%s, expected=%s)" % [reason, str(actual), str(expected)])
    return false
