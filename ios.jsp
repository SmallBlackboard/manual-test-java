<html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="http://cdn.bootcss.com/bootstrap/3.3.0/css/bootstrap.min.css">
    <script type="text/javascript" src="js/jquery-3.1.1.min.js"></script>

    <style type="text/css">
        #screenshot {
            width: auto;
            height: 100%;
            cursor: pointer;
        }
    </style>
<script>

    var appWidth = 0, appHeight = 0;
    var imgWidth = 0, imgHeight = 0;
    var scaleX = 1, scaleY = 1;


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

        var screenshot = document.getElementById('screenshot');

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

    function clickFunc(func) {
        saveCommand(func, '');
    }


</script>

</head>
<body>


<div style="text-align: center">
    <p>
        <button type="button" onclick="clickFunc('home')" class="btn btn-sm btn-info">home</button>
    </p>
    <img id="screenshot" class="img-thumbnail" data-holder-rendered="true">
</div>


</body>
</html>
