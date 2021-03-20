set -x
echo ${SSH_KEY}
echo ${SSH_KEY} | wc -l

echo "================================"
echo -ne ${SSH_KEY}
echo -ne ${SSH_KEY} | wc -l