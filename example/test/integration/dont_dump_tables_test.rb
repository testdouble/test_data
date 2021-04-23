require "test_helper"

class DontDumpTablesTest < SerializedNonTransactionalTestCase
  def test_dump_includes_zero_chatty_audit_logs
    assert_equal 0, ChattyAuditLog.count
  end
end
