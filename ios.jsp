<%--
  Created by IntelliJ IDEA.
  User: mac
  Date: 2016/12/7
  Time: 上午10:26
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<style type="text/css">
    html, body {
        margin: 0;
        padding: 0;
        width: 100%;
        height: 100%;
        overflow-y: hidden;
    }

    #screenContainer {
        position: absolute;
        width: 100%;
        height: 100%;
        text-align: center;

    }

    #keyinput {
        position: absolute;
        left: 5px;
        top: 5px;
    }

    #screenshot {
        width: auto;
        height: 100%;
        cursor: pointer;
    }

    /*#loadingContainer{*/
    /*position:absolute;*/
    /*width:100%;*/
    /*height:100%;*/
    /*z-index:99;*/
    /*cursor:wait*/
    /*}*/
    /*#loadingContainer img{*/
    /*position:absolute;*/
    /*top:50%;*/
    /*left:50%;*/
    /*margin-top:-200px;*/
    /*margin-left:-100px;*/
    /*}*/
    .line {
        position: absolute;
        background: red;
        left: 0;
        top: 0;
        width: 1px;
        height: 1px;
        z-index: 999;
    }
</style>


<script type="text/javascript" src="js/jquery-3.1.1.min.js"></script>

<script>

    var mapNodeValueCount = {};
    var appTree = null;

    var appSource = '';
    var appTree = '';
    var appWidth = 0, appHeight = 0;
    var imgWidth = 0, imgHeight = 0;
    var checkResult = true;
    var scaleX = 1, scaleY = 1;

    var mapNodeValueCount = {};


    var arrKeyAttrs = ['resource-id', 'name', 'text'];



    function request_get() {
//        $.get("http://localhost:8900/screenshot/" , function (data) {
//            var appInfo = JSON.parse(data);
//            $('#screenshot').attr('src', 'data:image/png;base64,' + appInfo.value);
//        });

        var data = {
            type: 'mobileAppInfo'
        };
        socket.send(JSON.stringify(data));

    }

    function saveCommand(cmd, data) {
        var cmdData = {
            cmd: cmd,
            data: data
        };

        var data = {
            type: 'command',
            data: cmdData
        };
        socket.send(JSON.stringify(data));

    }

    var socket = new WebSocket('ws://localhost:9765');


    $(document).ready(function () {

        var loadingContainer = document.getElementById('loadingContainer');
        var screenshot = document.getElementById('screenshot');
        var topLine = document.getElementById('topLine');
        var bottomLine = document.getElementById('bottomLine');
        var leftLine = document.getElementById('leftLine');
        var rightLine = document.getElementById('rightLine');
        var keyinput = document.getElementById('keyinput');

        var downX = -9999;
        var downY = -9999;


        // 打开Socket
        socket.onopen = function (event) {

            // 监听消息
            socket.onmessage = function (event) {

                var message = event.data;
                try {
                    message = JSON.parse(message);
                }
                catch (e) {

                }
                ;
                var type = message.type;
                console.log('type', type);
                switch (type) {
                    case 'mobileAppInfo':
                        var appInfo = message.data;

//                        appSource = appInfo.source;

//                        appTree = appSource.tree || appSource.hierarchy.node;
//                        scanAllNode();
                        $('#screenshot').attr('src', 'data:image/png;base64,' + appInfo.screenshot);
                        appWidth = screenshot.naturalWidth;
                        appHeight = screenshot.naturalHeight;
                        imgWidth = screenshot.width;
                        imgHeight = screenshot.height;
                        scaleX = appWidth / imgWidth;
                        scaleY = appHeight / imgHeight;
                        if (imgWidth != 0) {
                            scaleX = appWidth / imgWidth;
                            scaleY = appHeight / imgHeight;
                        }


                        break;
                }
                ;
                console.log('Client received a message', event);
            };

            // 监听Socket的关闭
            socket.onclose = function (event) {
                console.log('Client notified socket has closed', event);
            };

            // 关闭Socket....
            //socket.close()

        };


        setInterval("request_get()", 500);//1000为1秒钟


        $('#screenshot').click(function (event) {

            var upX = event.offsetX, upY = event.offsetY;

            if (Math.abs(downX - upX) < 20 && Math.abs(downY - upY) < 20) {
                saveCommand('click', {
                    touchX: Math.floor(upX * scaleX/2),
                    touchY: Math.floor(upY * scaleY/2)
                });
            }
            event.stopPropagation();
            event.preventDefault();

        });


        $('#screenshot').on('mousedown', function (event) {
            downX = event.offsetX;
            downY = event.offsetY;
            event.stopPropagation();
            event.preventDefault();
        });

        $('#screenshot').on('mouseup', function (event) {
            var upX = event.offsetX, upY = event.offsetY;
            if (Math.abs(downX - upX) >= 20 || Math.abs(downY - upY) >= 20) {
                saveCommand('swipe', {
                    startX: Math.floor(downX * scaleX/2),
                    startY: Math.floor(downY * scaleY/2),
                    endX: Math.floor(upX * scaleX/2),
                    endY: Math.floor(upY * scaleY/2),
                    duration: 20
                });
            }
            event.stopPropagation();
            event.preventDefault();
        });



    });


</script>

<html>
<head>
    <title>$Title$</title>
</head>
<body>
<div id="screenContainer">
    <img id="screenshot">
</div>
<div id="loadingContainer">
</div>
<div id="topLine" class="line"></div>
<div id="bottomLine" class="line"></div>
<div id="leftLine" class="line"></div>
<div id="rightLine" class="line"></div>
<input type="text" id="keyinput" style="display:none"/>

</body>
</html>
