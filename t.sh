set -x
echo ${PLUGIN_SSH_KEY}
echo ${PLUGIN_SSH_KEY} | wc -l
echo ${GIT_PUSH_SSH_KEY}
echo ${GIT_PUSH_SSH_KEY} | wc -l


echo "================================"
echo -ne ${PLUGIN_SSH_KEY}
echo -ne ${PLUGIN_SSH_KEY} | wc -l
echo -ne ${GIT_PUSH_SSH_KEY}
echo -ne ${GIT_PUSH_SSH_KEY} | wc -l