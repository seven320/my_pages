# ref: https://github.com/maxheld83/ghpages/blob/master/entrypoint.sh

# 特定のリポジトリの内容をPreview用の別リポジトリにpushする
set -e
WORKDIR=`pwd`
REMOTE_BRANCH="gh-pages"

# Function to check if a variable is set
check_variable() {
    local var_name="$1"
    local var_value="$2"

    if [ -z "${var_value}" ]; then
        echo "Error: ${var_name} environment variable is not set."
        exit 1
    fi
}

check_variable "BUILD_DIR" "${BUILD_DIR}"
# check_variable "REMOTE_BRANCH" "${REMOTE_BRANCH}"
check_variable "REMOTE_REPOSITORY" "${REMOTE_REPOSITORY}"
check_variable "DEPLOY_MODE" "${DEPLOY_MODE}"

echo "---------------------------"
echo "BUILD_DIR is ${BUILD_DIR}"
echo "REMOTE_BRANCH is ${REMOTE_BRANCH}"
# create or deleteの時のみ必要
echo "PREVIEW_DIR" is ${PREVIEW_DIR}
echo "REMOTE_REPOSITORY is ${REMOTE_REPOSITORY}"
echo "DEPLOY_ENV is ${DEPLOY_ENV}"
echo "DEPLOY_MODE is ${DEPLOY_MODE}" 
echo "---------------------------"

# git clone ${REMOTE_REPOSITORY}
# cd ${REMOTE_REPOSITORY##*/}

if git show-ref --verify --quiet refs/heads/${REMOTE_BRANCH}; then
    echo "Branch ${REMOTE_BRANCH} exists. Checking out..."
    git checkout 
else
    echo "Branch ${REMOTE_BRANCH} does not exist. Creating a new branch..."
    git checkout -b ${REMOTE_BRANCH}
fi
cd ${WORKDIR}

if [ "${DEPLOY_ENV}" = "prd" ];then
    echo "Deploy Prd Pages..."
    rm -rf ${DEPLOY_REPOSITORY##*/}docs/build/prd/
    cp -rf BUILD_DIR ${DEPLOY_REPOSITORY##*/}docs/build/prd/. #my-pages/docs/build/prd/
elif [ "${DEPLOY_ENV}" = "dev" ];then
    if [ "${DEPLOY_MODE}" = "create" ];then
        echo "Making Dev ${PREVIEW_DIR} preview Pages..."
        mkdir -p ${DEPLOY_REPOSITORY##*/}docs/build/dev${PREVIEW_DIR}
        rm -rf ${DEPLOY_REPOSITORY##*/}docs/build/dev${PREVIEW_DIR}* # 
        cp -rf BUILD_DIR ${DEPLOY_REPOSITORY##*/}docs/build/dev${PREVIEW_DIR}/. #my-pages/docs/build/dev/<branch_name>/
    elif [ "${DEPLOY_MODE}" = "delete" ];then
        echo "Deleting ${PREVIEW_DIR} preview..."
        rm -rf ${DEPLOY_REPOSITORY##*/}docs/build/dev/${PREVIEW_DIR}
    else    
        echo "Error! argument DEPLOY_MODE must be a 'create' or 'delete'"
        exit 1
    fi
    # echo "Making preview readme..."
    # cp -f create_preview_readme.py ${DEPLOY_REPOSITORY##*/}/.
    # cd ${DEPLOY_REPOSITORY##*/}
    # python3 create_preview_readme.py
else
    echo "Error! argument DEPLOY_ENV must be a 'prd' or 'dev'"
    exit 1
fi

git config user.name "${GITHUB_ACTOR}" && \
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com" && \
if [ -z "$(git status --porcelain)" ]; then
    echo "Nothing to commit" && \
    exit 0

fi && \
git add . && \
git commit -m 'Deploy to GitHub Pages' && \
git push --force ${REMOTE_REPOSITORY} ${REMOTE_BRANCH}:${REMOTE_BRANCH} && \
rm -fr .git && \
cd ${GITHUB_WORKSPACE} && \
echo "Content of ${BUILD_DIR} has been deployed to GitHub Pages."