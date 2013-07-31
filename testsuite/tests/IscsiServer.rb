# encoding: utf-8

module Yast
  class IscsiServerClient < Client
    def main
      # testedfiles: IscsiLioServer.ycp

      Yast.include self, "testsuite.rb"
      TESTSUITE_INIT([], nil)

      Yast.import "IscsiLioServer"

      DUMP("IscsiLioServer::Modified")
      TEST(lambda { IscsiLioServer.Modified }, [], nil)

      nil
    end
  end
end

Yast::IscsiServerClient.new.main
