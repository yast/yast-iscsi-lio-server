# Simple example to demonstrate object API for CWM

# require_relative "example_helper"
require './src/lib/helps/example_helper.rb'
require './src/lib/TargetData.rb'
require 'cwm/widget'
require 'ui/service_status'
require 'yast'
require 'cwm/table'
require 'cwm/dialog'
require 'yast2/execute'

Yast.import 'CWM'
Yast.import 'CWMTab'
Yast.import 'TablePopup'
Yast.import 'CWMServiceStart'
Yast.import 'Popup'
Yast.import 'Wizard'
Yast.import 'CWMFirewallInterfaces'
Yast.import 'SuSEFirewall'
Yast.import 'Service'
Yast.import 'CWMServiceStart'
Yast.import 'UI'
Yast.import 'TablePopup'

class NoDiscoveryAuth_CheckBox < ::CWM::CheckBox
  def initialize(container,value)
    textdomain "iscsi-lio-server"
    @config = value
    @container_class = container
  end

  def label
    _('No Discovery Authentication')
  end

  def init
    self.value = @config
  end

  def store
    $discovery_auth.store_status(self.value)
  end

  def handle
    if self.value == false
      @container_class.disable_discovery_auth_widgets()
    else
      @container_class.enable_discovery_auth_widgets()
    end
    nil
  end

  def opt
    [:notify]
  end
end

# used to enable / disable 0.0.0.0 IP portal
class BindAllIP < ::CWM::CheckBox
  def initialize(val)
    textdomain "iscsi-lio-server"
    @config = val
  end

  def label
    _('Bind all IP addresses')
  end

  def init
    self.value = @config
  end

  def opt
    [:notify]
  end

  def get_value
    return self.value
  end
end

class UseLoginAuth < ::CWM::CheckBox
  def initialize(val)
    textdomain "iscsi-lio-server"
    @config = val
  end

  def label
    _('Use Login Authentication')
  end

  def init
    self.value = @config
  end

  def store
    @config = self.value
  end

  def get_value
    return self.value
  end

  def set_value(val)
    self.value = val
  end

  def opt
    [:notify]
  end
end

# Class used to check whether initiator side auth is enabled
class Auth_by_Initiators_CheckBox < ::CWM::CheckBox
  def initialize(container, value)
    textdomain "iscsi-lio-server"
    @container_class = container
    @config = value
  end

  def label
    _("Authentication by Initiators\n")
  end

  def init
    self.value = @config
    if self.value == false
      @container_class.disable_input_fields()
    else
      @container_class.enable_input_fields()
    end
  end

  def set_value(val)
    self.value = val
  end

  def get_value
    return self.value
  end

  def handle
    if self.value == false
      @container_class.disable_input_fields()
    else
      @container_class.enable_input_fields()
    end
    nil
  end

  def opt
    [:notify]
  end
end

class Auth_by_Targets_CheckBox < ::CWM::CheckBox
  def initialize(container, value)
    textdomain "iscsi-lio-server"
    @container_class = container
    @config = value
  end

  def label
    _('Autnentication by Targets')
  end

  def init
    self.value = @config
    if self.value == false
      @container_class.disable_input_fields()
    else
      @container_class.enable_input_fields()
    end
  end

  def set_value(val)
    self.value = val
  end

  def get_value
    return self.value
  end

  def handle
    if self.value == false
      @container_class.disable_input_fields()
    else
      @container_class.enable_input_fields()
    end
    nil
  end

  def opt
    [:notify]
  end
end

class UserName < CWM::InputField
  def initialize(str)
    textdomain "iscsi-lio-server"
    if str == " \n"
      @config = ""
    else
      @config = str
    end
  end

  def label
    _('Username:')
  end

  def init
    self.value = @config
  end

  def store
    @config = value
  end

  def get_value()
    return self.value
  end

  def set_value(str)
    self.value = str
  end

  def validate
    if self.enabled? == true
      if self.value.empty? == true
        err_msg = _("username can not be empty.")
        Yast::Popup.Error(err_msg)
        return false
      end
      err_msg = _("Can not use ")
      illegal_chars = ""
      chars = ["`", "'", "[", "]", "{", "}", "=", "&", "*", "?", "^", "$", "#" ,"|", " "]
      chars.each do |char|
        if self.value.include?(char)
          illegal_chars += char
          illegal_chars += ", "
        end
      end
      if illegal_chars.empty? != true
        err_msg = _("Can not use such characters: ") + illegal_chars + _("in username.")
        Yast::Popup.Error(err_msg)
        return false
      end
    end
    return true
  end
end

class Password < CWM::InputField
  def initialize(str)
    textdomain "iscsi-lio-server"
    if str == " \n"
      @config = ""
    else
      @config = str
    end
  end

  def label
    _('Password:')
  end

  def init
    self.value = @config
  end

  def store
    @config = value
  end

  def get_value()
    return self.value
  end

  def validate
    if self.enabled? == true
      if self.value.empty? == true
        err_msg = _("password can not be empty.")
        Yast::Popup.Error(err_msg)
        return false
      end
      err_msg = _("Can not use ")
      illegal_chars = ""
      chars = ["`", "'", "[", "]", "{", "}", "=", "&", "*", "?", "^", "$", "#" ,"|", " "]
      chars.each do |char|
        if self.value.include?(char)
          illegal_chars += char
          illegal_chars += ", "
        end
      end
      if illegal_chars.empty? != true
        err_msg = _("Can not use such characters: ") + illegal_chars + _("in password.")
        Yast::Popup.Error(err_msg)
        return false
      end
    end
    return true
  end
end

class MutualUserName < CWM::InputField
  def initialize(str)
    textdomain "iscsi-lio-server"
    if str == " \n"
      @config = ""
    else
      @config = str
    end
  end

  def label
    _('Mutual Username:')
  end

  def init
    self.value = @config
  end

  def store
    @config = value
  end

  def get_value()
    return self.value
  end

  def validate
    if self.enabled? == true
      if self.value.empty? == true
        err_msg = _("mutual_username can not be empty.")
        Yast::Popup.Error(err_msg)
        return false
      end
      err_msg = _("Can not use ")
      illegal_chars = ""
      chars = ["`", "'", "[", "]", "{", "}", "=", "&", "*", "?", "^", "$", "#" ,"|", " "]
      chars.each do |char|
        if self.value.include?(char)
          illegal_chars += char
          illegal_chars += ", "
        end
      end
      if illegal_chars.empty? != true
        err_msg = _("Can not use such characters: ") + illegal_chars + _("in mutual_username.")
        Yast::Popup.Error(err_msg)
        return false
      end
    end
    return true
  end
end

class MutualPassword < CWM::InputField
  def initialize(str)
    textdomain "iscsi-lio-server"
    if str == " \n"
      @config = ""
    else
      @config = str
    end
  end

  def label
    _('Mutual Password:')
  end

  def init
    self.value = @config
  end

  def store
    @config = value
  end

  def get_value()
    return self.value
  end

  def validate
    if self.enabled? == true
      if self.value.empty? == true
        err_msg = _("mutual_password can not be empty.")
        Yast::Popup.Error(err_msg)
        return false
      end
      err_msg = _("Can not use ")
      illegal_chars = ""
      chars = ["`", "'", "[", "]", "{", "}", "=", "&", "*", "?", "^", "$", "#" ,"|", " "]
      chars.each do |char|
        if self.value.include?(char)
          illegal_chars += char
          illegal_chars += ", "
        end
      end
      if illegal_chars.empty? != true
        err_msg = _("Can not use such characters: ") + illegal_chars + _("in mutual_password.")
        Yast::Popup.Error(err_msg)
        return false
      end
    end
    return true
  end
end

module Yast
  class ServiceTab < ::CWM::Tab
    include Yast::I18n
    include Yast::UIShortcuts
    def initialize
      textdomain "iscsi-lio-server"
      self.initial = true
      @service = Yast::SystemdService.find("sshd.service")
      @service_status = ::UI::ServiceStatus.new(@service, reload_flag: true, reload_flag_label: :restart)
    end
    def contents
      HBox(
          @service_status.widget
      )
    end

    def handle(event)
      puts event
      @service_status.handle_input(event["ID"])
      nil
    end

    def opt
      [:notify]
    end

    def label
      _('Service')
    end
  end
end


class TargetAuthDiscovery < CWM::CustomWidget
  include Yast
  include Yast::I18n
  include Yast::UIShortcuts
  include Yast::Logger
  def initialize(value)
    textdomain "iscsi-lio-server"
    username = $discovery_auth.fetch_userid.gsub(/\s+/,'')
    password = $discovery_auth.fetch_password.gsub(/\s+/,'')
    @auth_by_target = Auth_by_Targets_CheckBox.new(self, value)
    @user_name_input = UserName.new(username)
    @password_input = Password.new(password)
    self.handle_all_events = true
  end


  def contents
    HCenter(
        VBox(
            @auth_by_target,
            HBox(
                @user_name_input,
                @password_input,
            ),
        )

    )
=begin
    VBox(
        @auth_by_target,
        HBox(
            @user_name_input,
            @password_input,
        ),
    )
=end
  end

  def disable_checkbox()
    @auth_by_target.set_value(false)
    @auth_by_target.disable()
  end

  def enable_checkbox()
    @auth_by_target.enable()
    @auth_by_target.value = true
  end

  def disable_input_fields()
    @user_name_input.disable()
    @password_input.disable()
  end

  def enable_input_fields()
    @user_name_input.enable()
    @password_input.enable()
  end

  def get_status
    return @auth_by_target.value()
  end

  def opt
    [:notify]
  end

  def validate
    status = @auth_by_target.get_value
    if status == true
      if (@user_name_input.get_value == " \n") || (@password_input.get_value == " \n")
        err_msg = _("Please use username and password in pair.")
        Yast::Popup.Error(err_msg)
        return false
      end
    end
    true
  end

  def store()
    username = @user_name_input.get_value.gsub(/\s+/,'')
    password = @password_input.get_value.gsub(/\s+/,'')
    $discovery_auth.store_userid(username)
    $discovery_auth.store_password(password)
  end

  def handle(event)
    nil
  end

  def help
    _('demo help')
  end
end

class InitiatorAuthDiscovery < CWM::CustomWidget
  include Yast
  include Yast::I18n
  include Yast::UIShortcuts
  include Yast::Logger
  def initialize(value)
    textdomain "iscsi-lio-server"
    @auth_by_initiator = Auth_by_Initiators_CheckBox.new(self, value)
    mutual_username = $discovery_auth.fetch_mutual_userid().gsub(/\s+/,'')
    mutual_password = $discovery_auth.fetch_mutual_password().gsub(/\s+/,'')
    @mutual_user_name_input = MutualUserName.new(mutual_username)
    @mutual_password_input = MutualPassword.new(mutual_password)
    self.handle_all_events = true
  end

  def contents
    VBox(
        @auth_by_initiator,
        HBox(
            @mutual_user_name_input,
            @mutual_password_input,
        ),
    )
  end

  def disable_checkbox()
    @auth_by_initiator.set_value(false)
    @auth_by_initiator.disable()
  end

  def enable_checkbox()
    @auth_by_initiator.enable()
    @auth_by_initiator.value = true
  end

  def disable_input_fields()
    @mutual_user_name_input.disable()
    @mutual_password_input.disable()
  end

  def enable_input_fields()
    @mutual_user_name_input.enable()
    @mutual_password_input.enable()
  end

  def get_status
    return @auth_by_initiator.value
  end

  def opt
    [:notify]
  end

  def validate
    status = @auth_by_initiator.get_value
    if status == true
      if (@mutual_user_name_input.get_value == " \n") || (@mutual_password_input.get_value == " \n")
        err_msg = _("Please use mutual_username and mutual_password in pair.")
        Yast::Popup.Error(err_msg)
        return false
      end
    end
    true
  end

  def store()
    mutual_username = @mutual_user_name_input.get_value.gsub(/\s+/,'')
    mutual_password = @mutual_password_input.get_value.gsub(/\s+/,'')
    $discovery_auth.store_mutual_userid(mutual_username)
    $discovery_auth.store_mutual_password(mutual_password)
  end

  def handle(event)
    nil
  end

  def help
    _('demo help')
  end
end

class DiscoveryAuthWidget < CWM::CustomWidget
  include Yast
  include Yast::I18n
  include Yast::UIShortcuts
  include Yast::Logger
  def initialize()
    textdomain "iscsi-lio-server"
    $discovery_auth.analyze()
    @status = $discovery_auth.fetch_status()
    if @status == "False \n"
      value = false
    else
      value = true
    end
    @no_discovery_auth_checkbox = NoDiscoveryAuth_CheckBox.new(self, value)
    @target_discovery_auth = TargetAuthDiscovery.new(value)
    @initiator_discovery_auth = InitiatorAuthDiscovery.new(value)
    self.handle_all_events = true
  end

  def init()
    if @status == "False \n"
      disable_discovery_auth_widgets()
    end
  end

  def disable_discovery_auth_widgets
    @target_discovery_auth.disable_checkbox()
    @target_discovery_auth.disable_input_fields()
    @initiator_discovery_auth.disable_checkbox()
    @initiator_discovery_auth.disable_input_fields()
  end

  def enable_discovery_auth_widgets
    @target_discovery_auth.enable_checkbox()
    @target_discovery_auth.enable_input_fields()
    @initiator_discovery_auth.enable_checkbox()
    @initiator_discovery_auth.enable_input_fields()
  end

  def contents
    HVCenter(
        VBox(
            HSpacing(2),
            Left(
                @no_discovery_auth_checkbox
            ),
            @target_discovery_auth,
            @initiator_discovery_auth,
        ),
    )
=begin
    VBox(
        @no_discovery_auth_checkbox,
        @target_discovery_auth,
        @initiator_discovery_auth,
    )
=end
  end

  def opt
    [:notify]
  end

  def validate
    if @no_discovery_auth_checkbox.value == true
      if (@target_discovery_auth.get_status == false) || (@initiator_discovery_auth.get_status ==false)
        err_msg = _("When Discovery Authentication is enabled.")
        err_msg += _("Plese use Authentication by initiator and Authentication by targets together.")
        Yast::Popup.Error(err_msg)
        return false
      end
    end
    true
  end

  def handle(event)
    nil
  end

  def help
    _('demo help')
  end
end

class GlobalTab < ::CWM::Tab
  def initialize
    textdomain "iscsi-lio-server"
    @discovery_auth = DiscoveryAuthWidget.new()
    self.initial = true
  end

  def contents
    VBox(
      HStretch(),
      VStretch(),
      @discovery_auth,
    )
  end

  def label
    _('Global')
  end
end

class TargetsTab < ::CWM::Tab
  def initialize
    textdomain "iscsi-lio-server"
    @target_table_widget = TargetsTableWidget.new
    self.initial = false
  end

  def contents
    VBox(
      HStretch(),
      VStretch(),
      @target_table_widget
    )
  end

  def label
    _('Targets')
  end
end

class TargetNameInput < CWM::InputField
  def initialize(str)
    textdomain "iscsi-lio-server"
    @config = str.downcase
    @iscsi_name_length_max = 233
  end

  def label
    _('Target')
  end

  def validate
    if value.empty?
      Yast::Popup.Error(_('Target name cannot be empty.'))
      return false
    elsif value.bytesize > @iscsi_name_length_max
      Yast::Popup.Error(_('Target name cannot be longger than 223 bytes.'))
      return false
    end
    true
  end

  def init
    self.value = @config.downcase
  end

  def store
    @config = value.downcase
  end

  def get_value
    value.downcase
  end
end

class TargetIdentifierInput < CWM::InputField
  def initialize(str)
    @config = str.downcase
  end

  def label
    _('Identifier')
  end

  def validate
    self.value = @config.downcase
    true
  end

  def init
    self.value = @config.downcase
  end

  def store
    @config = value.downcase
  end

  def get_value
    value.downcase
  end
end

class PortalGroupInput < CWM::IntField
  def initialize(num)
    textdomain "iscsi-lio-server"
    @config = num.to_i
  end

  def label
    _('Portal Group')
  end

  def init
    self.value = @config
  end

  def store
    @config = value
  end

  def minimum
    0
  end
end

class TargetPortNumberInput < CWM::IntField
  def initialize(int)
    textdomain "iscsi-lio-server"
    @config = int
  end

  def label
    _('Port Number')
  end

  def init
    self.value = @config
  end

  def store
    @config = value
  end

  def get_value
    return self.value
  end

  def set_value(int)
    self.value = int
    puts "int is:", int
    puts "self.value is", self.value
  end

  def minimum
    0
  end
end

class IpSelectionComboBox < CWM::ComboBox
  def initialize
    @addr = generate_items
    @config = "0.0.0.0"
  end

  def label
    _('IP Address:')
  end

  def init
  end

  def GetNetConfig
    ip_list = []
    re_ipv4 = Regexp.new(/[\d+\.]+\//)
    re_ipv6 = Regexp.new(/[\w+\:]+\//)
    ret = Yast::Execute.locally('ip', 'a', stdout: :capture)
    ip = ret.split("\n")
    ip.each do |line|
      line = line.strip
      if line.include?('inet') && !line.include?('deprecated') # don't show deprecated IPs
        if line.include?('inet6')
          ip_str = re_ipv6.match(line).to_s.delete!('/')
          if ip_str.start_with?('::1')
            next
          elsif ip_str.start_with?('fe80:')
            next
          else
            ip_list.push(ip_str)
          end
        else
          # delete "/", and drop 127.x.x.x locall address
          ip_str = re_ipv4.match(line).to_s.delete!('/')
          if ip_str.start_with?('127.')
            next
          else
            ip_list.push(ip_str)
          end
        end
      end
    end
    ip_list
  end

  def addresses
    self.GetNetConfig
  end

  def generate_items
    address_array = self.GetNetConfig
    addr = []
    address_array.each do |elem|
      addr.push([rand(9999),elem])
    end
    return addr
  end

  def items
    @addr
  end

  def get_addr
    @addr.each do |item|
      if item[0] == self.value
        return item[1]
      end
    end
  end

  def set_addr(ip)
    addr_temp = []
    item_temp = []
    @addr.each do |item|
      if item[1] == ip
        item_temp = item
        @addr.delete(item)
      end
    end
    addr_temp.push(item_temp)
    @addr.each do |item|
      addr_temp.push(item)
    end
    @addr = addr_temp
    self.change_items(@addr)
  end

  def store

  end

  def opt
    [:notify]
  end
end

class ACLTable < CWM::Table
  def initialize(target_name,tpg)
    textdomain "iscsi-lio-server"
    @target_name = target_name
    @tpg_num = tpg
    @acls = generate_items()
    @acls_add =[]
    @acls_delete = []
  end

  def get_all_acls_hash
    $target_data.analyze()
    all_acls_hash = Hash.new()
    target_list = $target_data.get_target_list
    target = target_list.fetch_target(@target_name)
    tpg = target.get_default_tpg
    #we only has one acl group called "acls"
    if tpg != nil
      acls_group_hash = tpg.fetch_acls("acls")
    else
      err_msg = _("There are no TPGs in the target!")
      Yast::Popup.Error(err_msg)
    end
    if acls_group_hash != nil
      all_acls_hash = acls_group_hash.get_all_acls()
    end
    return all_acls_hash
  end

  def generate_items
    acls = Array.new()
    auth_str = ""
    all_acls_hash = get_all_acls_hash()
    all_acls_hash.each do |key,value|
      lun_mappig_str = get_lun_mapping_str(value)
      auth_str = get_auth_str(value)
      if auth_str.empty? == true
        # add a space following None, becasue we need to -1 below
        auth_str = "None "
      end
      item = [rand(999), key, lun_mappig_str[0, lun_mappig_str.length - 1], auth_str[0, auth_str.length - 1]]
      acls.push(item)
    end
    return acls
  end

  # This function will return lun mapping str like: 0->1, 2->3
  def get_lun_mapping_str(acl_rule)
    lun_mappig_str = String.new()
    mapped_lun = acl_rule.get_mapped_lun()
    mapped_lun.each do |key, value|
      lun_mappig_str += value.fetch_mapped_lun_number  + "->" + value.fetch_mapping_lun_number + ","
    end
    return lun_mappig_str
  end

  # This function will return auth str, like "authentication by targets"
  def get_auth_str(acl_rule)
    auth_str = ""
    userid = acl_rule.fetch_userid
    password = acl_rule.fetch_password
    mutual_userid = acl_rule.fetch_mutual_userid
    mutual_password = acl_rule.fetch_mutual_password
    # Notice: when empty userid or password, it is " \n"(a space and \n)
    if (userid != " \n") && (password != " \n")
      auth_str += _("Authentication by Target,")
    end
    if (mutual_userid != " \n") && (mutual_password != " \n")
      auth_str += _("Authentication by Initiator,")
    end
    return auth_str
  end


  def get_selected()
    @acls.each do |item|
      if item[0] == self.value
        return item
      end
    end
  end

  def add_item(item)
    @acls.push(item)
    @acls_add.push(item)
    self.change_items(@acls)
  end

  def delete_item(item)
    @acls_delete.push(item)

    @acls.each do |elem|
      if elem[1] == item[1]
        @acls.delete(elem)
      end
    end

    @acls_add.each do |elem|
      if elem[1] == item[1]
        @acls_add.delete(elem)
      end
    end

    self.change_items(@acls)
  end

  def header
    [_('Initiator'), _('LUN Mapping'), _('Auth')]
  end

  def items
    @acls
  end

  def enable_auto_add_mapped_luns
    cmd = "targetcli"
    p1 = "set global auto_add_mapped_luns=true"
    begin
      Cheetah.run(cmd, p1)
    rescue Cheetah::ExecutionFailed => e
      if e.stderr != nil
        Yast::Popup.Error(e.stderr)
        # TODO add log
      end
    end
  end

  def disable_auto_add_mapped_luns
    cmd = "targetcli"
    p1 = "set global auto_add_mapped_luns=false"
    begin
      Cheetah.run(cmd, p1)
    rescue Cheetah::ExecutionFailed => e
      if e.stderr != nil
        Yast::Popup.Error(e.stderr)
        # TODO add log
      end
    end
  end

  def validate
    cmd = "targetcli"
    err_msg = _("Failed to create ACLs witn initiator name: ")
    failed_acls = ""
    @acls_delete.each do |elem|
      p1 = "iscsi/" + @target_name + "/tpg" + @tpg_num.to_s + "/acls delete " + elem[1]
      begin
        Cheetah.run(cmd, p1)
      rescue Cheetah::ExecutionFailed => e
        #TODO add log here
      end
    end

    @acls_add.each do |elem|
      p1 = "iscsi/" + @target_name + "/tpg" + @tpg_num.to_s + "/acls create " + elem[1]
      if (elem[0] < 5000)
        enable_auto_add_mapped_luns()
      else
        disable_auto_add_mapped_luns()
      end
      begin
        Cheetah.run(cmd, p1)
      rescue Cheetah::ExecutionFailed => e
        if e.stderr != nil
          failed_acls += (elem[1] + "\n")
          @acls.delete(elem)
          self.change_items(@acls)
        end
      end
      if (elem[0] < 5000)
        disable_auto_add_mapped_luns()
      end

      if failed_acls.empty? != true
        err_msg += failed_acls
        err_msg += _("Please check whether initiator names are valid.")
        Yast::Popup.Error(err_msg)
        return false
      end

      true
    end
  end

end


class InitiatorNameInput < CWM::InputField
  def initialize()
    textdomain "iscsi-lio-server"
  end

  def label
    _('Initiator Name:')
  end

  def init
    self.value = ""
  end

  def store
    @config = self.value
  end

  def validate
    iscsi_name_max_length = 233
    if value.empty? == true
      err_msg = _("Initiator name can not be empty!")
      Yast::Popup.Error(err_msg)
      return false
    end

    if value.bytesize > iscsi_name_max_length
      err_msg = _("Initiator name can not be longger than 233 bytes!")
      Yast::Popup.Error(err_msg)
      return false
    end
    return true
  end

  def get_value
    return @config
  end
end

class ImportLUNsCheckbox < ::CWM::CheckBox
  def initialize(val)
    textdomain "iscsi-lio-server"
    @config = val
  end

  def label
    _('Import all LUNs from current TPG')
  end

  def init
    self.value = @config
  end

  def store
    @config = self.value
  end

  def get_value
    return @config
  end


  def opt
    [:notify]
  end
end

class AddAclDialog < CWM::Dialog
  def initialize
    textdomain "iscsi-lio-server"
    @initiator_name_input = InitiatorNameInput.new
    @import_luns = ImportLUNsCheckbox.new(true)
    @action = ""
  end

  def wizard_create_dialog
    Yast::UI.OpenDialog(layout)
    yield
  ensure
    Yast::UI.CloseDialog()
  end

  def title
    _("Add an initiator")
  end

  def contents
    VBox(
        @initiator_name_input,
        @import_luns,
        HBox(
            PushButton(Id(:cancel), _('Cancel')),
            PushButton(Id(:ok), _('OK')),
        ),
    )
  end

  def should_open_dialog?
    true
  end

  def layout
    VBox(
        Left(Heading(Id(:title), title)),
        MinSize(70, 10, ReplacePoint(Id(:contents), Empty())),
    )
  end

  def run
    super
    initiator_name = @initiator_name_input.get_value()
    map_all_luns = @import_luns.get_value
    info = [initiator_name, map_all_luns]
    return info
  end
end


class LUNMappingTable < CWM::Table
  def initialize(initiator_name, target_name)
    textdomain "iscsi-lio-server"
    @initiator_name = initiator_name
    @target_name = target_name
    @tpg_num = nil
    @mapping_luns = Array.new()
    @mapping_luns = generate_items()
    @mapping_luns_added = Array.new()
  end

  def generate_items
    mapping = Array.new()
    mapped_lun = nil
    $target_data.analyze()
    all_acls_hash = Hash.new()
    target_list = $target_data.get_target_list
    target = target_list.fetch_target(@target_name)
    tpg = target.get_default_tpg()
    @tpg_num = tpg.fetch_tpg_number()
    if tpg != nil
      acls_group_hash = tpg.fetch_acls("acls")
    else
      err_msg = _("There are no TPGs in the target!")
      Yast::Popup.Error(err_msg)
    end
    if acls_group_hash != nil
      all_acls_hash = acls_group_hash.get_all_acls()
    end
    all_acls_hash.each do |key, value|
      if @initiator_name == key
        mapped_lun = value.get_mapped_lun()
      end
    end
    mapped_lun.each do |key, value|
      mapping.push([rand(999), value.fetch_mapping_lun_number, value.fetch_mapped_lun_number])
    end
    return mapping
  end

  def add_item(initiator_lun_num, target_lun_num)
    item = [rand(999), initiator_lun_num, target_lun_num]
    @mapping_luns.push(item)
    @mapping_luns_added.push(item)
    self.change_items(@mapping_luns)
  end

  def remove_item

  end

  def header
    [_('Initiator LUN'), _('Target LUN')]
  end

  def items
    @mapping_luns
  end

  def validate
    if @tpg_num == nil
      err_msg = _("There are not TPGs in this target.")
      Yast::Popup.Error(err_msg)
      return false
    end
    failed_mapping_luns = Array.new()
    cmd = 'targetcli'
    @mapping_luns_added.each do |elem|
      p1 = 'iscsi/' + @target_name + "/tpg" + @tpg_num + "/acls/" + @initiator_name + "/ create mapped_lun=" + \
      elem[1].to_s + " tpg_lun_or_backstore=" + elem[2].to_s
      begin
        Cheetah.run(cmd, p1)
      rescue Cheetah::ExecutionFailed => e
        if e.stderr != nil
          failed_mapping_luns.push(elem)
        end
      end
    end
    if failed_mapping_luns.empty? == false
      err_msg = _("Failed to map such target side LUN number:\n")
      failed_mapping_luns.each do |item|
        err_msg += item[2].to_s
        err_msg += ","
        @mapping_luns.delete_if { |elem| elem[0] == item[0] }
        @mapping_luns_added.delete_if { |elem| elem[0] == item[0] }
      end
      err_msg = err_msg[0, err_msg.length - 1]
      err_msg += _("\nPlease check whether the both LUN numbers in use and the LUNs still exists.")
      Yast::Popup.Error(err_msg)
      self.change_items(@mapping_luns)
      return false
    end
    true
  end
end

# This class used to input initiator side lun number, used in adding a lun mapping pare
class InitiatorLUNNumInput < CWM::IntField
  def initialize(int)
    textdomain "iscsi-lio-server"
    @config = int
  end

  def label
    _('Initiator side LUN number:')
  end

  def init
    self.value = @config
  end

  def minimum
    -1
  end

  def store
    @config = value
  end

  def get_value
    return @config
  end
end

# This class used to input target side lun number, used in adding a lun mapping pare
class TargetLUNNumInput < CWM::IntField
  def initialize(int)
    textdomain "iscsi-lio-server"
    @config = int
  end

  def label
    _('Target side LUN number:')
  end

  def init
    self.value = @config
  end

  def minimum
    -1
  end

  def store
    @config = value
  end

  def get_value
    return @config
  end
end


class AddLUNMappingDialog < CWM::Dialog
  def initialize
    @initiator_lun_num = InitiatorLUNNumInput.new(-1)
    @target_lun_num = TargetLUNNumInput.new(-1)
  end

  def title
    _('Add a LUN mapping pair')
  end

  def wizard_create_dialog
    Yast::UI.OpenDialog(layout)
    yield
  ensure
    Yast::UI.CloseDialog()
  end

  def contents
    VBox(
        HBox(
            @initiator_lun_num = InitiatorLUNNumInput.new(-1),
            @target_lun_num = TargetLUNNumInput.new(-1),
        ),
        HBox(
            PushButton(Id(:ok), _('OK')),
            PushButton(Id(:abort), _('Abort')),
        ),
    )
  end

  def should_open_dialog?
    true
  end

  def layout
    VBox(
        HSpacing(50),
        Left(Heading(Id(:title), title)),
        VStretch(),
        VSpacing(1),
        MinSize(80, 10, ReplacePoint(Id(:contents), Empty())),
        VSpacing(1),
        VStretch()
    )
  end

  def get_mapping_lun_pair()
    mapping_lun_pair = Array.new()
    initiator_lun_num = @initiator_lun_num.get_value()
    target_lun_num = @target_lun_num.get_value()
    mapping_lun_pair.push(initiator_lun_num)
    mapping_lun_pair.push(target_lun_num)
  end

  def run
    super
    return get_mapping_lun_pair()
  end
end

# This class used to edit lun mapping, contains a lun mapping table and buttons
class EditLUNMappingWidget < CWM::CustomWidget
  include Yast
  include Yast::I18n
  include Yast::UIShortcuts
  include Yast::Logger
  def initialize(initiator_name, target_name)
    textdomain "iscsi-lio-server"
    self.handle_all_events = true
    @lun_mapping_table = LUNMappingTable.new(initiator_name, target_name)
    @add_lun_mapping_dialog = AddLUNMappingDialog.new()
  end

  def contents
    VBox(
        @lun_mapping_table,
        HBox(
            PushButton(Id(:add), _('Add')),
            PushButton(Id(:delete), _('Delete')),
            PushButton(Id(:ok), _('OK')),
            PushButton(Id(:abort), _('Abort')),
        ),
    )
  end

  def opt
    [:notify]
  end

  def validate
    true
  end

  def handle(event)
    case event['ID']
      when :add
        mapping_lun_pair = @add_lun_mapping_dialog.run()
        initiator_lun_num = mapping_lun_pair[0]
        target_lun_num = mapping_lun_pair[1]
        if (initiator_lun_num < 0) || (target_lun_num < 0)
          return nil
        else
          @lun_mapping_table.add_item(initiator_lun_num, target_lun_num)
        end
    end
    nil
  end

  def help
    _('demo help')
  end
end



class EditLUNMappingDialog < CWM::Dialog
  def initialize(initiator_name, target_name)
    textdomain "iscsi-lio-server"
    @lun_mapping_widget = EditLUNMappingWidget.new(initiator_name, target_name)
  end


  def wizard_create_dialog
    Yast::UI.OpenDialog(layout)
    yield
  ensure
    Yast::UI.CloseDialog()
  end

  def title
    _('Edit LUN mapping')
  end

  def contents
    VBox(
        @lun_mapping_widget,
    )
  end

  def should_open_dialog?
    true
  end

  def layout
    VBox(
        Left(Heading(Id(:title), title)),
        MinSize(50, 20, ReplacePoint(Id(:contents), Empty())),
    )
  end

  def run
    super
  end
end

class ACLInitiatorAuth < CWM::CustomWidget
  include Yast
  include Yast::I18n
  include Yast::UIShortcuts
  include Yast::Logger
  def initialize(acl_hash, info)
    textdomain "iscsi-lio-server"
    @info = info
    mutual_username = acl_hash.fetch_mutual_userid.gsub(/\s+/,'')
    mutual_password = acl_hash.fetch_mutual_password.gsub(/\s+/,'')
    @mutual_user_name_input = MutualUserName.new(mutual_username)
    @mutual_password_input = MutualPassword.new(mutual_password)
    if (mutual_password.empty? != true) && (mutual_username.empty? != true)
      @auth_by_initiator = Auth_by_Initiators_CheckBox.new(self, true)
      enable_input_fields
    else
      @auth_by_initiator = Auth_by_Initiators_CheckBox.new(self, false)
    end
    self.handle_all_events = true
  end

  def init()
    if @auth_by_initiator.value == false
      disable_input_fields()
    end
  end

  def contents
        VBox(
            @auth_by_initiator,
            HBox(
                @mutual_user_name_input,
                @mutual_password_input,
            ),
        )
  end

  def disable_input_fields()
    @mutual_user_name_input.disable()
    @mutual_password_input.disable()
  end

  def enable_input_fields()
    @mutual_user_name_input.enable()
    @mutual_password_input.enable()
  end

  def opt
    [:notify]
  end

  def handle(event)
    nil
  end

  def validate()
    mutual_username = @mutual_user_name_input.get_value.gsub(/\s+/,'')
    mutual_password = @mutual_password_input.get_value.gsub(/\s+/,'')
    target_name = @info[0]
    tpg_num = @info[1]
    initiator_name = @info[2]
    cmd = "targetcli"
    if @auth_by_initiator.value == true
      p1 = "iscsi/" +  target_name + "/tpg" + tpg_num + "/acls/" + initiator_name + \
         "/ set auth mutual_userid=" + mutual_username + " mutual_password=" + mutual_password
      begin
        Cheetah.run(cmd, p1)
      rescue Cheetah::ExecutionFailed => e
        if e.stderr != nil
          err_msg = _("Failed to change Authentication by Initiators.")
          err_msg += e.stderr
          Yast::Popup.Error(err_msg)
          return false
        end
      end
    else
      p1 = "iscsi/" +  target_name + "/tpg" + tpg_num + "/acls/" + initiator_name + \
         "/ set auth mutual_userid="
      p2 = "iscsi/" +  target_name + "/tpg" + tpg_num + "/acls/" + initiator_name + \
         "/ set auth mutual_password="
      begin
        Cheetah.run(cmd, p1)
      rescue Cheetah::ExecutionFailed => e
        if e.stderr != nil
          err_msg = _("Failed to clear Authentication by Initiators.")
          err_msg += e.stderr
          Yast::Popup.Error(err_msg)
          return false
        end
      end

      begin
        Cheetah.run(cmd, p2)
      rescue Cheetah::ExecutionFailed => e
        if e.stderr != nil
          err_msg = _("Failed to clear Authentication by Initiators.")
          err_msg += e.stderr
          Yast::Popup.Error(err_msg)
          return false
        end
      end
    end
    return true
  end

  def help
    _('demo help')
  end
end

class ACLTargetAuth < CWM::CustomWidget
  include Yast
  include Yast::I18n
  include Yast::UIShortcuts
  include Yast::Logger
  def initialize(acl_hash, info)
    textdomain "iscsi-lio-server"
    @info = info
    username = acl_hash.fetch_userid.gsub(/\s+/,'')
    password = acl_hash.fetch_password.gsub(/\s+/,'')
    @user_name_input = UserName.new(username)
    @password_input = Password.new(password)
    if (password.empty? != true) && (username.empty? != true)
      @auth_by_target = Auth_by_Targets_CheckBox.new(self, true)
    else
      @auth_by_target = Auth_by_Targets_CheckBox.new(self, false)
    end
    self.handle_all_events = true
  end

  def init()
    if @auth_by_target.value == false
      disable_input_fields()
    end
  end

  def contents
    VBox(
        @auth_by_target,
        HBox(
            @user_name_input,
            @password_input,
        ),
    )
  end

  def disable_input_fields()
    @user_name_input.disable()
    @password_input.disable()
  end

  def enable_input_fields()
    @user_name_input.enable()
    @password_input.enable()
  end

  def opt
    [:notify]
  end

  def handle(event)
    nil
  end


  def validate()
    username = @user_name_input.get_value.gsub(/\s+/,'')
    password = @password_input.get_value.gsub(/\s+/,'')
    target_name = @info[0]
    tpg_num = @info[1]
    initiator_name = @info[2]
    cmd = "targetcli"
    if @auth_by_target.value == true
      p1 = "iscsi/" +  target_name + "/tpg" + tpg_num + "/acls/" + initiator_name + \
         "/ set auth userid=" + username + " password=" + password
      begin
        Cheetah.run(cmd, p1)
      rescue Cheetah::ExecutionFailed => e
        if e.stderr != nil
          err_msg = _("Failed to change Authentication by Targets.")
          err_msg += e.stderr
          Yast::Popup.Error(err_msg)
          return false
        end
      end
    else
      p1 = "iscsi/" +  target_name + "/tpg" + tpg_num + "/acls/" + initiator_name + \
         "/ set auth userid="
      p2 = "iscsi/" +  target_name + "/tpg" + tpg_num + "/acls/" + initiator_name + \
         "/ set auth password="
      begin
        Cheetah.run(cmd, p1)
      rescue Cheetah::ExecutionFailed => e
        if e.stderr != nil
          err_msg = _("Failed to clear Authentication by Targets.")
          err_msg += e.stderr
          Yast::Popup.Error(err_msg)
          return false
        end
      end

      begin
        Cheetah.run(cmd, p2)
      rescue Cheetah::ExecutionFailed => e
        if e.stderr != nil
          err_msg = _("Failed to clear Authentication by Targets.")
          err_msg += e.stderr
          Yast::Popup.Error(err_msg)
          return false
        end
      end
    end
    return true
  end

  def help
    _('demo help')
  end
end

# This classed used in EditAuthDialog
class EditAuthWidget < CWM::CustomWidget
  include Yast
  include Yast::I18n
  include Yast::UIShortcuts
  include Yast::Logger
  def initialize(initiator_name, target_name, tpg)
    textdomain "iscsi-lio-server"
    $target_data.analyze()
    all_acls_hash = Hash.new()
    target_list = $target_data.get_target_list
    target = target_list.fetch_target(target_name)
    tpg = target.get_default_tpg()
    tpg_num = tpg.fetch_tpg_number()
    if tpg != nil
      acls_group_hash = tpg.fetch_acls("acls")
    else
      err_msg = _("There are no TPGs in the target!")
      Yast::Popup.Error(err_msg)
    end
    if acls_group_hash != nil
      all_acls_hash = acls_group_hash.get_all_acls()
    end
    info = [target_name, tpg_num, initiator_name]
    all_acls_hash.each do |key, value|
      if key == initiator_name
        @acl_initiator_auth = ACLInitiatorAuth.new(value, info)
        @acl_target_auth = ACLTargetAuth.new(value, info)
      end
    end
    self.handle_all_events = true
  end

  def contents
    VBox(
        @acl_initiator_auth,
        @acl_target_auth,
        HBox(
            PushButton(Id(:ok), _('OK')),
            PushButton(Id(:abort), _('Abort')),
        ),
    )
  end

  def opt
    [:notify]
  end

  def validate
    true
  end

  def handle(event)
    nil
  end

  def help
    _('demo help')
  end
end

# This class used to edit initiator / target auth, not global
class EditAuthDialog < CWM::Dialog
  def initialize(initiator_name, target_name, tpg)
    @edit_auth_widget = EditAuthWidget.new(initiator_name, target_name, tpg)
  end

  def wizard_create_dialog
    Yast::UI.OpenDialog(layout)
    yield
  ensure
    Yast::UI.CloseDialog()
  end

  def title
    _('Authentication')
  end

  def contents
    VBox(
        @edit_auth_widget,
    )
  end

  def should_open_dialog?
    true
  end

  def layout
    VBox(
        Left(Heading(Id(:title), title)),
        MinSize(70, 15, ReplacePoint(Id(:contents), Empty())),
    )
  end

  def run
    super
  end
end

#Class to handle initiator acls, will shown after creating or editing targets.
class InitiatorACLs < CWM::CustomWidget
  def initialize(target_name, tpg_num)
    textdomain "iscsi-lio-server"
    self.handle_all_events = false
    @target_tpg = tpg_num
    @target_name = target_name
    @target_name_input = TargetNameInput.new(target_name)
    @target_portal_input = PortalGroupInput.new(@target_tpg)
    @acls_table = ACLTable.new(target_name,tpg_num.to_i)
    @add_acl_dialog = AddAclDialog.new()
  end

  def init
    @target_name_input.disable()
    @target_portal_input.disable()
  end

  def opt
    [:notify]
  end

  def contents
    VBox(
        HBox(
            @target_name_input,
            @target_portal_input,
        ),
        @acls_table,
        HBox(
            PushButton(Id(:add), _('Add')),
            PushButton(Id(:edit_lun), _('Edit LUN')),
            PushButton(Id(:edit_auth), _('Edit Auth')),
            PushButton(Id(:delete), _('Delete')),
        )
    )
  end

  def validate
    cmd = "targetcli iscsi/" + @target_name + "/tpg" + @target_tpg + "/ get attribute authentication"
    cmd_out = `#{cmd}`
    ret = cmd_out[15, cmd_out.length]
    if ret == "1 \n"
      msg = _("Use Login Authentication is enabled. Please make sure proper ACLs has been added.") + \
          _("Or the target may not be accsessible. Do you want to proceed?")
      ret = Yast::Popup.ErrorAnyQuestion(_("Warning"), msg, _("Yes"), _("No"), :focus_yes)
      if ret == true
        return true
      else
        return false
      end
    end
    return true
  end

  def handle(event)
    case event["ID"]
      when :add
        info = @add_acl_dialog.run
        initiator_name = info[0]
        mapped_all_luns = info[1]
        if initiator_name.empty? != true
          item = Array.new()
          # item[0] < 5000 means we will map all luns, item[0] > 5000 means we don't map all luns
          if(mapped_all_luns == true)
            item.push(rand(0..4999))
          else
            item.push(rand(5001..9999))
          end
          item.push(initiator_name)
          item.push("")
          item.push("None")
          @acls_table.add_item(item)
        end
      when :edit_lun
        item = @acls_table.get_selected()
        initiator_name = item[1]
        edit_lun_mapping_dialog = EditLUNMappingDialog.new(initiator_name, @target_name)
        ret = edit_lun_mapping_dialog.run
      when :edit_auth
        item = @acls_table.get_selected()
        initiator_name = item[1]
        @edit_auth_dialog = EditAuthDialog.new(initiator_name, @target_name,@target_tpg)
        @edit_auth_dialog.run
      when :delete
        item = @acls_table.get_selected()
        @acls_table.delete_item(item)
  end
    nil
  end

  def help
    _("demo help in InitaitorACLs")
  end
end

# This class is used for both adding a target and editing a target
class AddTargetWidget < CWM::CustomWidget
  include Yast
  include Yast::I18n
  include Yast::UIShortcuts
  include Yast::Logger

  def initialize(target_name)
    textdomain "iscsi-lio-server"
    self.handle_all_events = true
    $target_data.analyze
    @iscsi_name_length_max = 223
    @back_storage = nil
    @target_name = nil
    @edit_target_tpg = nil
    # @target_info used to return target name, portal number, etc to the caller, in order to create ACLs
    @target_info = Array.new
    # luns contains the luns would be shown in the lun table
    luns = nil
    # if mode == "new", need to create targets and luns, if mode == "edit", just change the target config
    @mode = nil
    time = Time.new
    date_str = time.strftime('%Y-%m')
    @IP_selsection_box = IpSelectionComboBox.new
    @target_bind_all_ip_checkbox = BindAllIP.new(true)
    @target_port_num_field = TargetPortNumberInput.new(3260)
    if target_name == nil
      @mode = 'new'
      @target_name_input_field = TargetNameInput.new('iqn.' + date_str + '.com.example')
      @target_identifier_input_field = TargetIdentifierInput.new(SecureRandom.hex(10))
      @target_portal_group_field = PortalGroupInput.new(1)
    else
      @mode = 'edit'
      tpg_num = 0
      target_list = $target_data.get_target_list
      target = target_list.fetch_target(target_name)
      tpg = target.get_default_tpg
      target = target_list.fetch_target(target_name)
      tpg_num = target.get_default_tpg.fetch_tpg_number
      @tpg_num = tpg_num
      @target_tgp = tpg
      portals = tpg.fetch_portal
      ip = portals[0][0]
      port = portals[0][1]
      if ip != "0.0.0.0"
        @target_bind_all_ip_checkbox = BindAllIP.new(false)
      end
      @IP_selsection_box.set_addr(ip)
      @target_port_num_field = TargetPortNumberInput.new(portals[0][1].to_i)
      luns = target.get_default_tpg.get_luns_array
      @target_name_input_field = TargetNameInput.new(target_name)
      @target_name = target_name
      @target_identifier_input_field = TargetIdentifierInput.new('')
      @target_portal_group_field = PortalGroupInput.new(tpg_num)
    end

    @lun_table_widget = LUNsTableWidget.new(luns, target_name, tpg_num)
    if @mode == 'new'
      @use_login_auth = UseLoginAuth.new(false)
    end

    if @mode == 'edit'
      cmd = "targetcli iscsi/" + @target_name + "/tpg" + @tpg_num + "/ get attribute authentication"
      cmd_out = `#{cmd}`
      ret = cmd_out[15, cmd_out.length]
      if ret == "1 \n"
        @use_login_auth = UseLoginAuth.new(true)
      else
        @use_login_auth = UseLoginAuth.new(false)
      end
    end
  end

  def opt
    [:notify]
  end

  def contents
    VBox(
      HBox(
        @target_name_input_field,
        @target_identifier_input_field,
        @target_portal_group_field
      ),
      HBox(
        @IP_selsection_box,
        @target_port_num_field
      ),
      VBox(
        @target_bind_all_ip_checkbox,
        @use_login_auth
      ),
      @lun_table_widget
    )
  end

  def validate
    portal_addr = @IP_selsection_box.get_addr
    port = @target_port_num_field.get_value.to_s
    bind_all = @target_bind_all_ip_checkbox.get_value
    cmd = 'targetcli'
    if @mode == 'new'
      p1 = 'iscsi/ create'
      if @target_name_input_field.get_value.bytesize > @iscsi_name_length_max
        @target_name = @target_name_input_field.get_value
      else
        @target_name = @target_name_input_field.get_value + ':' + @target_identifier_input_field.get_value
      end
      begin
        Cheetah.run(cmd, p1, @target_name)
      rescue Cheetah::ExecutionFailed => e
        if e.stderr != nil
          err_msg = _('Can not create the target with target name: ') + \
                    @target_name + _(", plese check target name.\n") + \
                    _('Additional information: ') + e.stderr
          Yast::Popup.Error(err_msg)
          return false
        end
      end
      target_tpg = @target_portal_group_field.value.to_s
      # Yast only support one TPG, targetcli will create a default tpg =1, if users provided another tpg number,
      # we need to delete tpg=1, then create another tpg based on the user provided number
      if target_tpg != '1'
        p1 = 'iscsi/' + @target_name + '/ delete tag=1'
        p2 = 'iscsi/' + @target_name + '/ create tag=' + target_tpg
        begin
          Cheetah.run(cmd, p1)
        rescue Cheetah::ExecutionFailed => e
          unless e.stderr.nil?
            err_msg = _('Target Portal Group number ') + target_tpg + _(' is provided to replace the defalult tpg') \
            + _('Failed to delete the default tpg, please consider to re-create the target and check') \
            + _('whether someone called targetcli manually')
            Yast::Popup.Error(err_msg)
            return false
          end
        end
        begin
          Cheetah.run(cmd, p2)
        rescue Cheetah::ExecutionFailed => e
          unless e.stderr.nil?
            err_msg = _('Failed to create Target Portal Group ') + target_tpg \
            + _('The target is create, in the meanwhile, please delete it if needed.') \
            + _('Or a defalut target portal group 1 will be added to the target when you edit it.')
            err_msg +=("\n Note: 0.0.0.0(Bind all IP address) with a port may conflict with other IPs with the same port")
            Yast::Popup.Error(err_msg)
            return false
          end
        end
      end

      bind_all = @target_bind_all_ip_checkbox.get_value
      if bind_all == true
        portal_addr = "0.0.0.0"
      end
      p3 = "iscsi/" + @target_name + "/tpg" + target_tpg + "/portals/ create ip_address=" \
           + portal_addr + " ip_port=" + port
      begin
        Cheetah.run(cmd, p3)
      rescue Cheetah::ExecutionFailed => e
        if e.stderr != nil
          err_msg = _("The target is created, but failed to create a portal with selected address and port. ")
          err_msg += _("Are they alredy in use?")
          err_msg += _(" You can edit the targets again to change that.\n")
          err_msg += e.stderr
          Yast::Popup.Error(err_msg)
        end
      end

      @lun_table_widget.set_target_info(@target_name, target_tpg)
      @target_info.push(@target_name)
      @target_info.push(target_tpg)
      return true
    end

    if @mode == 'edit'
      @target_name = @target_name_input_field.get_value
      target_tpg = @target_portal_group_field.value.to_s
      @lun_table_widget.set_target_info(@target_name, target_tpg)
      target_list = $target_data.get_target_list
      target = target_list.fetch_target(@target_name)
      tpg = target.get_default_tpg
      portals = tpg.fetch_portal
      orig_ip = portals[0][0]
      orig_port = portals[0][1]
      ip = @IP_selsection_box.get_addr
      port = @target_port_num_field.value
      bind_all = @target_bind_all_ip_checkbox.get_value
      if bind_all == true
        ip = "0.0.0.0"
      end

      # if ip or port changed, we need to delete the original portal and create a new one
      if (ip != orig_ip) || (port != orig_port.to_s)
        p1 = "iscsi/" + @target_name + "/tpg" + target_tpg + "/portals/ delete ip_address=" \
           + orig_ip + " ip_port=" + orig_port.to_s
        p2 = "iscsi/" + @target_name + "/tpg" + target_tpg + "/portals/ create ip_address=" \
           + ip + " ip_port=" + port.to_s
        err = ""
        begin
          Cheetah.run(cmd, p1)
        rescue Cheetah::ExecutionFailed => e
          if e.stderr != nil
            err += e.stderr
          end
        end

        begin
          Cheetah.run(cmd, p2)
        rescue Cheetah::ExecutionFailed => e
          if e.stderr != nil
            err += e.stderr
          end
        end

        if err.empty? != true
          err_msg = _("Failed to change target portal.\n")
          Yast::Popup.Error(err_msg + err)
        end
      end

    end
    @target_info.push(@target_name)
    @target_info.push(target_tpg)
    auth = @use_login_auth.value
    if auth == true
      p1 = "iscsi/" + @target_name + "/tpg" + @tpg_num + "/ set attribute authentication=1 " + \
           " demo_mode_write_protect=1" + " cache_dynamic_acls=0" + " generate_node_acls=0"
    else
      p1 = "iscsi/" + @target_name + "/tpg" + @tpg_num + "/ set attribute authentication=0 " + \
           " demo_mode_write_protect=0" + " cache_dynamic_acls=1" + " generate_node_acls=1"
    end
    begin
      Cheetah.run(cmd, p1)
    rescue Cheetah::ExecutionFailed => e
      if e.stderr != nil
        err_msg = _("Failed to change authentication settings. ")
        err_msg += e.stderr
        Yast::Popup.Error(err_msg)
      end
    end
    true
  end

  # used to return target info like target name, portal number to caller, for example, to craete ACLs
  def get_target_info
    info = @target_info
    return info
  end

end

class TargetTable < CWM::Table
  def initialize
    textdomain "iscsi-lio-server"
    @targets = generate_items()
    @targets_names = $target_data.get_target_names_array
  end

  def generate_items
    $target_data.analyze()
    @targets_names = $target_data.get_target_names_array
    item_array = nil
    @targets = Array.new
    @targets_names.each do |elem|
      @targets.push([rand(9999), elem, 1, 'Enabled'])
    end
    item_array = @targets
    return item_array
  end

  def header
    [_('Targets'), _('Portal Group'), _('TPG Status')]
  end

  def items
    @targets
  end

  def get_selected
    @targets.each do |target|
      if target[0] == self.value
        return target
      end
    end
    return nil
  end

  def update_table
    $target_data.analyze
    @targets_names = $target_data.get_target_names_array
    change_items(generate_items)
  end
end

class TargetsTableWidget < CWM::CustomWidget
  include Yast
  include Yast::I18n
  include Yast::UIShortcuts
  include Yast::Logger
  def initialize
    textdomain "iscsi-lio-server"
    self.handle_all_events = true
    @target_table = TargetTable.new
    @add_target_page = nil
    @edit_target_page = nil
    # target_info will store target name, portal, etc
    @target_info = nil
  end

  def opt
    [:notify]
  end

  def contents
    VBox(
      Id(:targets_table),
      @target_table,
      HBox(
        PushButton(Id(:add), _('Add')),
        PushButton(Id(:edit), _('Edit')),
        PushButton(Id(:delete), _('Delete'))
      )
    )
  end

  def create_ACLs_dialog(info)
    if info.empty? != true
      cmd = "targetcli iscsi/" + info[0] + "/tpg" + info[1] + "/ get attribute authentication"
      cmd_out = `#{cmd}`
      ret = cmd_out[15, cmd_out.length]
      if ret == "1 \n"
        @initiator_acls = InitiatorACLs.new(info[0], info[1])
        contents = VBox(@initiator_acls)
        Yast::Wizard.CreateDialog
        CWM.show(contents, caption: _('Modify initiators ACLs'))
        Yast::Wizard.CloseDialog
      end
    end
  end

  def handle(event)
    case event['ID']
      when :add
        @add_target_page = AddTargetWidget.new(nil)
        contents = VBox(@add_target_page, HStretch(), VStretch())
        Yast::Wizard.CreateDialog
        ret = CWM.show(contents, caption: _('Add iSCSI Target'))
        Yast::Wizard.CloseDialog
        @target_table.update_table
        info = @add_target_page.get_target_info()
        create_ACLs_dialog(info)
      when :edit
        target = @target_table.get_selected
        if target != nil
          @edit_target_page = AddTargetWidget.new(target[1])
          contents = VBox(@edit_target_page, HStretch(), VStretch())
          Yast::Wizard.CreateDialog
          CWM.show(contents, caption: _('Edit iSCSI Target'))
          Yast::Wizard.CloseDialog
        end
        @target_table.update_table
        info = @edit_target_page.get_target_info()
        create_ACLs_dialog(info)
      when :delete
        cmd = 'targetcli'
        target = @target_table.get_selected
        if target == nil
          return nil
        end
        luns_list = $target_data.get_target_list.fetch_target(target[1]).get_default_tpg.get_luns_list
        luns_list.each do |key, value|
          p1 = "backstores/"
          if value[4] == "file"
            p1 += "fileio delete " + value[2]
          end
          if value[4] == "blockSpecial"
            p1 += "block delete " + value[2]
          end
          Cheetah.run(cmd, p1)
        end
        p2 = 'iscsi/ delete ' + target[1]
        begin
          Cheetah.run(cmd, p2)
        rescue Cheetah::ExecutionFailed => e
          if e.stderr != nil
            err_msg = _("Failed to delete target: ")
            err_msg += (target[1] + " .")
            err_msg += e.stderr
          end
          Yast::Popup.Error(err_msg)
        end
        $target_data.analyze()
        @target_table.update_table
    end
    nil
  end

  def help
    _('demo help')
  end
end

class LUNTable < CWM::Table
  def initialize(init_luns)
    textdomain "iscsi-lio-server"
    # @luns will store all luns exsisted and will be created
    @luns = init_luns
    # @luns_add will store the luns will be created, will not store any exsisted luns.
    @luns_added = []
    @luns_removed = []
    @luns = generate_items
    @target_name = nil
    @target_tpg = nil
  end

  def set_target_info(name, tpg)
    @target_name = name
    @target_tpg = tpg
  end

  def generate_items
    items_array = []
    if !@luns.nil?
      return @luns
    else
      @luns = []
    end
    @luns
  end

  def header
    [_('LUN'), _('Name'), _('Path')]
  end

  def items
    @luns
  end

  def get_selected()
    @luns.each do |item|
      if item[0] == self.value
        return item
      end
    end
  end

  # This function will return the array @luns, LUNsTableWidget will use this to decide the lun number
  def get_luns
    @luns
  end

  # This function will return the array @luns_added, means the new luns need to create
  def get_new_luns
    @luns_added
  end

  # this function will add a lun in the table, the parameter item is an array
  def add_lun_item(item)
    @luns.push(item)
    @luns_added.push(item)
    update_table()
  end

  # this function will remove the lun form lun table
  def table_remove_lun(path)
    @luns.each do |elem|
      if elem[3] == path
        @luns.delete(elem)
      end
    end
    @luns_added.each do |elem|
      if elem[3] == path
        @luns_added.delete(elem)
      end
    end
    self.change_items(@luns)
  end


  def validate
    failed_storage = String.new
    @luns_added.each do |lun|
      cmd = 'targetcli'
      if lun[2].empty? == false
        case lun[4]
          when "file"
            p1 = 'backstores/fileio create name=' + lun[2] + ' file_or_dev=' + lun[3]
            p2 = 'iscsi/' + @target_name + '/tpg' + @target_tpg + "/luns/ create " + \
                 'storage_object=/backstores/fileio/' + lun[2]
          when "blockSpecial"
            p1 = 'backstores/block create name=' + lun[2] + ' dev=' + lun[3]
            p2 = 'iscsi/' + @target_name + '/tpg' + @target_tpg + "/luns/ create " + \
                 'storage_object=/backstores/block/' + lun[2]
        end
        # create backstores using the backstore provided in lun[4]  if lun[2] is not empty.
        begin
          Cheetah.run(cmd, p1)
        rescue Cheetah::ExecutionFailed => e
          if e.stderr != nil
            failed_storage += (lun[3] + "\n")
            next
          end
        end
      else
        # command to create the lun in target tpg, no need to craete backstores if lun[2] is empty
        p2 = 'iscsi/' + @target_name + '/tpg' + @target_tpg + "/luns/ create " + 'storage_object=' + lun[3]
      end
      if lun[1].to_s != "-1"
        p2 += (' lun=' + lun[1].to_s)
      end
      begin
        Cheetah.run(cmd, p2)
      rescue Cheetah::ExecutionFailed => e
        if e.stderr != nil
          failed_storage += (lun[3] + "\n")
          table_remove_lun_item(lun[0])
          update_table()
          next
        end
      end
    end
    #Pop up messages if any failures.
    if failed_storage.empty? == false
      err_msg = _("Failed to create LUNs with such backstores:\n") + failed_storage + \
                  _("Please check whether the backstore or LUN number is in use, name is valid.") + \
                  _("Then delete the failed LUNs.\n")
      Yast::Popup.Error(err_msg)
      return false
      $target_data.analyze()
    end
    $target_data.analyze()
    true
  end

  def update_table()
    luns = generate_items
    change_items(luns)
  end

end

class LunNumInput < CWM::IntField
  def initialize(num)
    textdomain "iscsi-lio-server"
    @config = num
  end

  def label
    _("LUN Number(left '-1' here to auto generate)")
  end

  def init
    self.value = @config
  end

  def store
    @config = value
  end

  def minimum
    -1
  end

  def get_value
    return self.value
  end
end

class LUNPathInput < CWM::InputField
  def initialize(str)
    @config = str
  end

  def label
    _('LUN Path')
  end

  def validate
    if value.empty?
      Yast::UI.SetFocus(Id(widget_id))
      Yast::Popup.Error(_('LUN path cannot be empty.'))
      false
    else
      true
    end
  end

  def init
    self.value = @config
  end

  def store
    @config = value
  end

  def get_value
    return self.value
  end

  def set_value(path)
    self.value = path
  end
end

class LunNameInput < CWM::InputField
  def initialize(str)
    textdomain "iscsi-lio-server"
    @config = str
  end

  def label
    _('LUN Name(auto generated when empty)')
  end

  def validate
    true
  end

  def init
    self.value = @config
  end

  def store
    @config = value
  end

  def get_value
    value
  end
end

# This widget contains Lun path input and lun path browsing
class LUNPathEdit < CWM::CustomWidget
  include Yast
  include Yast::I18n
  include Yast::UIShortcuts
  include Yast::Logger
  def initialize
    textdomain "iscsi-lio-server"
    self.handle_all_events = true
    @path = nil
    @lun_path_input = LUNPathInput.new("")
  end

  def contents
    HBox(
      @lun_path_input,
      PushButton(Id(:browse), _('Browse'))
    )
  end

  def get_value
    return @lun_path_input.value
  end

  def store; end

  def validate
    file = @lun_path_input.value.to_s
    if file.empty?
      Yast::Popup.Error(_('LUN Path can not be empty!'))
      return false
    end
    if File.exist?(file) == false
      Yast::Popup.Error(_('The file does not exist!'))
      @lun_path_input.value = nil
      return false
    end
    file_type = File.ftype(file)
    if (file_type != 'blockSpecial') && (file_type != 'file')
      Yast::Popup.Error(_('Please provide a normal file or a block device.'))
      @lun_path_input.value = nil
      return false
    end
    true
  end

  def is_valid
    file = @lun_path_input.value.to_s
    if file.empty?
      return false
    end
    if File.exist?(file) == false
      return false
    end
    file_type = File.ftype(file)
    if (file_type != 'blockSpecial') && (file_type != 'file')
      return false
    end
    return true
  end

  def handle(event)
    case event['ID']
    when :browse
      file = UI.AskForExistingFile('/', '', _('Select a file or device'))
      unless file.nil?
        @lun_path_input.set_value(file)
      end
    end
    nil
  end

  def help
    _("Demo help")
  end
end

# This is a class to config LUN path, number and name, used in LUNDetailsWidget contents
class LUNConfig < CWM::CustomWidget
  def initialize
    textdomain "iscsi-lio-server"
    @lun_num_input = LunNumInput.new(nil)
    @lun_path_edit = LUNPathEdit.new
    @lun_name_input = LunNameInput.new(nil)
    @lun_info = nil
  end

  def contents
    VBox(
      @lun_num_input,
      @lun_path_edit,
      @lun_name_input,
      HBox(
        PushButton(Id(:cancel), _('Cancel')),
        PushButton(Id(:ok), _('OK'))
      )
    )
  end

  def validate
    if @lun_path_edit.is_valid == true
      @lun_info = Array.new
      @lun_info.push(@lun_num_input.get_value)
      @lun_info.push(@lun_name_input.get_value)
      @lun_info.push(@lun_path_edit.get_value)
    end
    true
  end

  def get_lun_info
    @lun_info
  end

  def help
    _("Demo help")
  end
end

class LUNDetailsWidget < CWM::Dialog
  def initialize
    textdomain "iscsi-lio-server"
    @lun_config = LUNConfig.new
  end

  def title
    _("LUN Details")
  end

  def wizard_create_dialog
    Yast::UI.OpenDialog(layout)
    yield
  ensure
    Yast::UI.CloseDialog()
  end

  def contents
    VBox(
      @lun_config
    )
  end

  def should_open_dialog?
    true
  end

  def layout
    VBox(
      HSpacing(50),
      Left(Heading(Id(:title), title)),
      VStretch(),
      VSpacing(1),
      MinSize(50, 18, ReplacePoint(Id(:contents), Empty())),
      VSpacing(1),
      VStretch()
    )
  end

  def run
    super
    @lun_config.get_lun_info
  end
end

class LUNsTableWidget < CWM::CustomWidget
  include Yast
  include Yast::I18n
  include Yast::UIShortcuts
  include Yast::Logger
  def initialize(luns, target_name, tpg_num)
    textdomain "iscsi-lio-server"
    self.handle_all_events = true
    @lun_table = LUNTable.new(luns)
    @lun_details = LUNDetailsWidget.new
    @target_name = target_name
    @tpg_num = tpg_num
  end

  def contents
    VBox(
      @lun_table,
      HBox(
        PushButton(Id(:add), _('Add')),
        PushButton(Id(:delete), _('Delete'))
      )
    )
  end

  # This function pass target name from AddTargetWidget to lun table
  def set_target_info(name, tpg)
    @lun_table.set_target_info(name, tpg)
  end

  # This function will return new luns, aka the newly added luns which needed to be created in tpg#N/luns
  def get_new_luns
    @lun_table.get_new_luns
  end

  def create_luns_backstores
    @lun_table.create_luns_backstore
  end

  def opt
    [:notify]
  end

  def validate
    true
  end

  def handle(event)
    case event['ID']
      when :add
        ret = @lun_details.run
        if ret != nil
          lun_number = ret[0]
          lun_name = ret[1]
          file = ret[2]
          if !file.nil? && (File.exist?(file) == true)
            @lun_table.add_lun_item([rand(9999), lun_number, lun_name, file, File.ftype(file)])
          end
        end
      when :delete
        lun = @lun_table.get_selected
        cmd = "targetcli"
        p1 = "backstores/"
        if lun[4] == "file"
          p1 += "fileio delete " + lun[2]
        end
        if lun[4] == "blockSpecial"
          p1 += "block delete " + lun[2]
        end
        p2 = "iscsi/" + @target_name + "/tpg" + @tpg_num + "/luns/ delete lun=" + lun[1]
        ret = nil
        if $global_data.del_lun_warning_enable? == true
          msg = _("This will immediately delete LUNs. ") + \
              _("Please confim all initiators have logged out this target to avoid IO errors") + \
              -("Do you want to proceed now?")
          ret = Yast::Popup.ErrorAnyQuestion(_("Confirm"), msg, _("Yes and Don't show this again"), _("No"), :focus_yes)
          if ret == true
            $global_data.disable_warning_del_lun
          end
        end
        # we will delete luns when ret == nil(not shown the warning dialog) or ret == true
        if ret != false
          begin
            Cheetah.run(cmd, p2)
          rescue Cheetah::ExecutionFailed => e
            if e.stderr != nil
              err_msg = _("Failed to delete backstore of lun") + lun[1] + \
                      _("Please check whether someone already did it.\n")
              err_msg += e.stderr
              Yast::Popup.Error(err_msg)
            end
          end

          begin
            Cheetah.run(cmd, p1)
          rescue Cheetah::ExecutionFailed => e
            if e.stderr != nil
              err_msg = _("Failed to delete lun") + lun[1] + \
                      _("Please check whether someone already did it.\n")
              err_msg += e.stderr
              Yast::Popup.Error(err_msg)
            end
          end
          @lun_table.table_remove_lun(lun[3])
        end
    end
    nil
  end

  def help
    _('demo help')
  end
end