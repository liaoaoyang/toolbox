#!/bin/sh

# bc on CentOS only allow uppercase letters

uuidgen | tr "a-f" "A-F" | tr -d "-" | xargs -I "{}" echo "obase=62;ibase=16;{}" | bc | sed 's/0\([0-9]\)/\1/g' | awk 'BEGIN{r=""}{
	for(i = 1; i <= NF; ++i) {
		if ($i < 10) {
			r = r""$i;
		} else if ($i < 36) {
			r = sprintf("%s%c", r, ($i - 10 + 97));
		} else {
			r = sprintf("%s%c", r, ($i - 36 + 65));
		}
	}
}
END {
	print r;
}'
