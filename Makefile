#
# $Id: Makefile 22 2008-12-10 14:03:26Z I.zaufi $
#

#
RES_COL = $$((`stty size 2>/dev/null | cut -d' ' -f2` - 5))
move_to_column = \\033[$(1)G
set_color = \\033[$(1)m
COLOR_BRACKET = 1;34
COLOR_SUCCESS = 1;32
COLOR_FAILURE = 1;31
COLOR_WARNING = 1;33
COLOR_NORMAL = 0;39
# 'OK' message
SUCCESS = echo -e "$(call move_to_column,$(RES_COL))$(call set_color,$(COLOR_BRACKET))[$(call set_color,$(COLOR_SUCCESS)) ok $(call set_color,$(COLOR_BRACKET))]"
# 'Fail' message
FAILURE = echo -e "$(call move_to_column,$(RES_COL))$(call set_color,$(COLOR_BRACKET))[$(call set_color,$(COLOR_FAILURE)) !! $(call set_color,$(COLOR_BRACKET))]"
#
EINFO = echo -e " $(call set_color,$(COLOR_SUCCESS))*$(call set_color,$(COLOR_NORMAL))"
EBEGIN = echo -e -n " $(call set_color,$(COLOR_SUCCESS))*$(call set_color,$(COLOR_NORMAL))"
#
MKMSG = echo make[$(MAKELEVEL)]:

package_name = team-expense-calc
test_files = $(wildcard tests/*-test.xml)
result_files = $(patsubst %-test.xml,%-result.xml,$(test_files))
etalon_files = $(patsubst %-test.xml,%-etalon.xml,$(test_files))

test_log_file = tec-unit-tests.log

all:
	@echo "Nothing to do..."

check: check-spam $(result_files) $(etalon_files)
	@$(EINFO) "Going to analyse results..."
	@for i in $(result_files); do \
	    ef=`echo $$i | sed 's,-result,-etalon,'`; \
	    $(EBEGIN) " Compare $$i and $$ef..."; \
	    diff $$i $$ef >/dev/null 2>&1 && $(SUCCESS) || $(FAILURE); \
	done; \
	echo -n " Cleanup result files..." && rm $(result_files) && $(SUCCESS) || $(FAILURE)

check-spam:
	@$(EINFO) "Going to execute tests..."

tests/%-etalon.xml: tests/%-result.xml
	@if ! test -f $@; then \
	    $(EBEGIN) " Produce etalon file from $<"; \
	    cp $< $@ && $(SUCCESS) || $(FAILURE); \
	fi

tests/%-result.xml: tests/%-test.xml
	@xsl=`grep '<\?xml-stylesheet' $<  | sed 's,.*href="\(.*\)".*,\1,'`; \
	$(EBEGIN) " Produce result file for $< using $$xsl"; \
	xsltproc $$xsl $< > $@ && xmllint --format $@ > $@.tmp && mv -f $@.tmp $@ && $(SUCCESS) || $(FAILURE)

dist: dist-zip

dist-zip:
	test -f $(package_name).zip && rm $(package_name).zip || true
	zip $(package_name).zip \
            css/tec.css \
            css/tec-layout.css \
            css/tec-green.css \
            css/tec-table.css \
            tec.xsl \
            tec-lib.xsl \
            tec.dtd \
            example.xml \
            images/ui-icons_256x240.png \
            js/tec.js \
            js/FixedHeader.js \
            js/jquery-1.9.1.js \
            js/jquery-migrate-1.1.0.js \
            js/jquery.dataTables.js

.PHONY: all check dist dist-zip
