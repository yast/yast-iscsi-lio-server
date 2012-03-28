# Makefile.am for iscsi-server/src

yncludedir = @yncludedir@/iscsi-lio-server

client_DATA =			\
	iscsi-lio-server.ycp		\
	iscsi-lio-server_auto.ycp	\
	iscsi-lio-server_proposal.ycp

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	dialogs.ycp		\
	complex.ycp		\
	widgets.ycp

desktop_DATA =			\
	iscsi-lio-server.desktop

module_DATA =			\
	IscsiLioServer.ycp	\
	IscsiLioData.ycp	\
	IscsiServerFunctions.pm

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
