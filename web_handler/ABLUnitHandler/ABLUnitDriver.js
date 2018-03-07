/*
    File        : ABLUnitDriver.js
    Purpose     : Call ABLUnit tests from a javascript client synchronously or asnychronously

    Author(s)   : isyed
    Created     : Tue Oct 10 17:13:00 EDT 2016

*/


$(document).ready(function () {


function generateUUID() {
    var d = new Date().getTime();
    if(window.performance && typeof window.performance.now === "function"){
        d += performance.now();; //use high-precision timer if available
    }
    var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = (d + Math.random()*16)%16 | 0;
        d = Math.floor(d/16);
        return (c=='x' ? r : (r&0x3|0x8)).toString(16);
    });
    return uuid;
};


function async(fn,sessionId,testname,parallel, callback) {
    setTimeout(function() {
        fn(sessionId,testname,parallel);
        callback();
    }, 0);
}



function InvokeTest(sessionId,testname,parallel){
	
   var TestList = '{"Sessionid":"' + sessionId + '","TimeStamp":"' + Date.now + '","ABLUnit":[{"tests":[{"test":"' + testname + '"}]}]}'
	
    
	$.ajax({
         type: "POST",
         //url: "http://localhost:8810/ABLWebDriver/web/auhandler/invoke",
         url: "../web/auhandler/invoke",
		 contentType: "application/json",
		 Accept: "application/json",
		 async: parallel,
		 data: TestList,
	
         success: function (data, status, xhr) {
		        console.log("done with " + testname);
			   },
         error: function (xhr, status) {
                console.log(xhr.status)
             // return "false";

         }
         })

}

var sessionId = "MultiRun" + generateUUID();
 //var tlist = '{"tests":["test2.p","PASOEAPITesting.cls,"Communities_testing.p"],"async":"true"}';
var tlist = '{"tests":["PASOEAPITesting.cls","Communities_testing.p"],"async":"true"}';
//  var tlist = '{"tests":["test1.p"],"async":"true"}';
//var tlist = '{"tests":["PASOEAPITesting.cls"],"async":"true"}';
//var tlist = '{"tests":["Communities_testing.p"],"async":"true"}';
//var tlist = '{"tests":["test2.p","test1.p"],"async":"false"}';

 var tlistpayload = JSON.parse(tlist);

 var tests = tlistpayload.tests;

 var parallel = tlistpayload.async;


 for (var i = 0; i < tests.length; i++) {

  console.log("The value of parallel is " + parallel);
 if (parallel == "true") {

     async(InvokeTest,sessionId,tests[i],true,function(){ 
   // console.log('got sessionid value as ' + sessionId);
});
 }
 else
 {
     console.log("Running sequentially");
     InvokeTest(sessionId,tests[i],false);
 }

}

 console.log('got sessionid value as ' + sessionId);

});
