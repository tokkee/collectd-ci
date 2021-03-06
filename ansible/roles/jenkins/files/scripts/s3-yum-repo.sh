#!/bin/sh

set -xe

test "x$(id -un)" = "xjenkins"

. "${WORKSPACE}/s3repo.sh"

test -n "$PKGDIR"
test -n "$BRANCH"
test -n "$DIST"
test -n "$COLLECTD_BUILD"

REPO="$PKGDIR/$BRANCH/$DIST"

test -d $REPO

if test "$DIST" = "epel-5-i386" || test "$DIST" = "epel-5-x86_64"; then
  createrepo -s sha "$REPO"
else
  createrepo "$REPO"
  gpg --detach-sign --armor --batch --default-key ci@collectd.org "$REPO/repodata/repomd.xml"
fi

cat << EOF > "$REPO/status.json"
{
  "branch": "${BRANCH}",
  "dist": "${DIST}",
  "collectd_build": "${COLLECTD_BUILD}"
}
EOF

test -f ~/.s3cfg

s3cmd --acl-public --delete-removed --no-progress sync "$REPO/" "s3://collectd/rpm/$BRANCH/$DIST/"
