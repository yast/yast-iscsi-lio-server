$LOAD_PATH << File.expand_path("../../src/include/iscsi-lio-server", __FILE__)

def fixture(name)
  fn = File.expand_path("../fixtures/#{name}", __FILE__)
  File.read(fn)
end
