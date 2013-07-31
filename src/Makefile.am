# Sources for iscsi-lio-server

module_DATA = \
  modules/IscsiLioServer.rb \
  modules/IscsiLioData.rb

client_DATA = \
  clients/iscsi-lio-server.rb \
  clients/iscsi-lio-server_proposal.rb \
  clients/iscsi-lio-server_auto.rb

yncludedir = @yncludedir@/iscsi-lio-server
ynclude_DATA = \
  include/iscsi-lio-server/widgets.rb \
  include/iscsi-lio-server/wizards.rb \
  include/iscsi-lio-server/dialogs.rb \
  include/iscsi-lio-server/complex.rb \
  include/iscsi-lio-server/helps.rb

scrconf_DATA = \
  scrconf/ietd.scr

desktop_DATA = \
  desktop/iscsi-lio-server.desktop

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(scrconf_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common