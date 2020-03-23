const git = require('simple-git/promise');
const avocado = require("@azure/avocado");
var templateIdRegex = "id: [0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}";
var targetBranch = process.env.SYSTEM_PULLREQUEST_TARGETBRANCH;
// const sourceBranch = 'source-b6791c5f-e0a5-49b1-9175-d7fd3e341cb8'

var config = avocado.cli.defaultConfig();
var workingDir = config.cwd;
var sourceBranch = avocado.devOps.createPullRequestProperties(config).sourceBranch;

async function getBranch(options) {
    var branchSummary = await git(workingDir).branch(options, null);
    return branchSummary;
}

async function getDiff(options) {
   let diffSummary = null;
   try {
       diffSummary = await git(workingDir).diff(options, null);
   }
   catch (e) {
      console.log("An error occerrued")
   }
   return diffSummary;
}

getBranch([]).then(function(branches){
    console.log("target: " + targetBranch);
    console.log("source: " + sourceBranch);
    // console.log("branch name: " + branches.current);
    var options = [targetBranch, sourceBranch];

    getDiff(options).then(function(result){
        console.log(result);
        if (result.search(templateIdRegex) > 0){
            console.log("Some of the files ID has changed")
        }    
        else {
            console.log("All tests passed successfuly")
        }    
    })    
});    















