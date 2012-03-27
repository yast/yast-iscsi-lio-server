# Makefile.am for iscsi-server/src

yncludedir = @yncludedir@/iscsi-server

client_DATA =			\
	iscsi-server.ycp		\
	iscsi-server_auto.ycp	\
	iscsi-server_proposal.ycp

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	dialogs.ycp		\
	complex.ycp		\
	widgets.ycp

desktop_DATA =			\
	iscsi-server.desktop

module_DATA =			\
	IscsiServer.ycp		\
	IscsiServerFunctions.pm

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
