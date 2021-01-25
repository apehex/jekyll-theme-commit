#!/bin/bash
#
# A harder variant.
#
# git log -p (--patch)
#   affiche toutes les diffs 

set -o nounset
set -o pipefail
set -o errexit

escape-segments() {
  python -c '
import cgi, re, sys

print re.sub(
  r"\x00([^\x00]*)\x00", 
  lambda match: cgi.escape(match.group(1)),
  sys.stdin.read())
'
}

count-nul() {
  # -o puts every match on its own line.  grep -o -c doesn't work.
  od -A n -t x1 | grep -o '00' | wc -l
}

test-count-nul() {
  python -c "print '\0x\0\0'" | count-nul
  python -c "print '\1'" | count-nul
}

# Takes a file on stdin, and expected NUL count as $1.  Fails if they don't
# match.
expect-nul-count() {
  local expected=$1

  local nul_count=0
  nul_count=$(count-nul)  # reads from stdin!

  if test "$nul_count" -ne "$expected"; then
    echo 1>&2 "Expected $expected NUL characters, got $nul_count"
    return 1
  fi
}

git-log-html() {
  echo '<link rel="stylesheet" href="manual.css" type="text/css" media="all">'
  echo '<div class="vertical-tabset">'

  local num_fields=2  # 2 fields contain arbitrary text
  local format='<div id="%H" class="vertical-tab">
    <input type="radio" name="git-log-html" id="option-%h">
    <label for="option-%h" class="tab-header"><div class="log-tree"></div><div class="title">%s</div></label>
    <section class="tab-panel">
    </section>
  </div>'

  local num_entries=5
  git log -n $num_entries --pretty="format:$format" > tmp.bin

  # Fails if we don't get the right number of NUL characters.
  expect-nul-count $((num_entries * num_fields * 2)) < tmp.bin

  # Writes HTML to stdout.
  escape-segments < tmp.bin

  echo '</div>'
}

write-file() {
  # NOTE: with -n 5 there is a slight race condition.
  git-log-html > git-log-multiline.html
  echo "Wrote git-log-multiline.html"
}

"$@"
