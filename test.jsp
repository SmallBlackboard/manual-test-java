<%@ page contentType="text/html;charset=UTF-8" language="java" %>

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
                    console.log('Client received a message', event);

                    var blob = new Blob([event.data], {type: 'image/jpeg'});
                    var u = URL.createObjectURL(blob);
                    $('#screenshot').attr('src', u);

                    appWidth = screenshot.naturalWidth;
                    appHeight = screenshot.naturalHeight;
                    imgWidth = screenshot.width;
                    imgHeight = screenshot.height;
                    if (imgWidth != 0) {
                        scaleX = appWidth / imgWidth;
                        scaleY = appHeight / imgHeight;
                    }


                };

                // 监听Socket的关闭
                socket.onclose = function (event) {
                    console.log('Client notified socket has closed', event);
                };

                // 关闭Socket....
                //socket.close()
            };


            $('#screenshot').click(function (event) {
                var upX = event.offsetX, upY = event.offsetY;

                if (Math.abs(downX - upX) < 20 && Math.abs(downY - upY) < 20) {
                    saveCommand('click', {
                        touchX: Math.floor(upX * scaleX),
                        touchY: Math.floor(upY * scaleY)
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
                        startX: Math.floor(downX * scaleX),
                        startY: Math.floor(downY * scaleY),
                        endX: Math.floor(upX * scaleX),
                        endY: Math.floor(upY * scaleY),
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
        <button type="button" onclick="clickFunc('menu')" class="btn btn-sm btn-info">menu</button>
        <button type="button" onclick="clickFunc('home')" class="btn btn-sm btn-info">home</button>
        <button type="button" onclick="clickFunc('back')" class="btn btn-sm btn-info">back</button>
    </p>
    <img id="screenshot" class="img-thumbnail" data-holder-rendered="true">
</div>


</body>
</html>
