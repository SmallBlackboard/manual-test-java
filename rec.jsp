<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="http://cdn.bootcss.com/bootstrap/3.3.0/css/bootstrap.min.css">
    <script type="text/javascript" src="js/jquery-3.1.1.min.js"></script>

    <style type="text/css">
        /*#screenshot {*/
            /*width: auto;*/
            /*height: 100%;*/
            /*cursor: pointer;*/
        /*}*/
    </style>

    <script>

        var appWidth = 0, appHeight = 0;
        var imgWidth = 0, imgHeight = 0;
        var scaleX = 1, scaleY = 1;
        var mapNodeValueCount = {};
        var arrKeyAttrs = ['resource-id', 'name', 'text'];

        var editor ;
        var appTree;

        function scanAllNode(){
            mapNodeValueCount = {};
            scanNode(appTree)
        }

        // 从左边读取限制长度的字符串
        function leftstr(text, limit) {
            var substr = '';
            var count = 0;
            var char;
            for (var i = 0, len = text.length; i < len; i++) {
                char = text.charCodeAt(i);
                substr += text.charAt(i);
                count += char > 255 ? 2 : 1;
                if (count >= limit) {
                    return substr;
                }
            }
            return substr;
        }


        function scanNode(node){
            arrKeyAttrs.forEach(function(name){
                var value = node[name];
                if(value){
                    var mapCount = mapNodeValueCount[name] || {};
                    mapCount[value] = mapCount[value] && mapCount[value] + 1 || 1;
                    mapNodeValueCount[name] = mapCount;
                }
            })
            node.class = node.class || ('XCUIElementType' + node.type);
            var bounds = node.bounds || '';
            var match = bounds.match(/^\[([\d\.]+),([\d\.]+)\]\[([\d\.]+),([\d\.]+)\]$/);
            if(match){
                node.startX = parseInt(match[1], 10);
                node.startY = parseInt(match[2], 10);
                node.endX = parseInt(match[3], 10);
                node.endY = parseInt(match[4], 10);
                node.boundSize = (node.endX - node.startX) * (node.endY - node.startY);
            }
            match = bounds.match(/\{([\d\.]+),\s*([\d\.]+)\},\s*\{([\d\.]+),\s*([\d\.]+)\}/);
            if(match){
                node.startX = parseInt(match[1], 10);
                node.startY = parseInt(match[2], 10);
                node.endX =  node.startX + parseInt(match[3], 10);
                node.endY = node.startY + parseInt(match[4], 10);
                node.boundSize = (node.endX - node.startX) * (node.endY - node.startY);
            }
            var childNodes = node.children || node.node;
            if(childNodes){
                node.children = childNodes;
                if(!Array.isArray(childNodes)){
                    childNodes = [childNodes];
                }
                var childNode;
                for(var i=0;i<childNodes.length;i++){
                    childNode = childNodes[i];
                    childNode.parentNode = node;
                    scanNode(childNode);
                }
            }
        }

        // get node info by x,y
        function getNodeInfo(x, y){
            var nodeInfo = {};
            var bestNodeInfo = {
                node: null,
                boundSize: 0
            };
            getBestNode(appTree, x, y, bestNodeInfo);
            var bestNode = bestNodeInfo.node;
            if(bestNode){
                var text = bestNode.text || bestNode.label;
                if(text){
                    text = text.replace(/\s*\r?\n\s*/g,' ');
                    text = text.replace(/^\s+|\s+$/g, '');
                    var textLen = byteLen(text);
                    text = textLen > 20 ? leftstr(text, 20) + '...' : text;
                    nodeInfo.text = text;
                }
                nodeInfo.path = getNodeXPath(bestNode);
            }
            else{
                nodeInfo.x = x;
                nodeInfo.y = y;
            }
            return nodeInfo;
        }
        function getBestNode(node, x, y, bestNodeInfo){
            if(node.boundSize && x >= node.startX && x <= node.endX && y >= node.startY && y <= node.endY){
                var childNodes = node.children;
                if(childNodes){
                    if(!Array.isArray(childNodes)){
                        childNodes = [childNodes];
                    }
                    for(var i=0;i<childNodes.length;i++){
                        getBestNode(childNodes[i], x, y, bestNodeInfo);
                    }
                }
                else{
                    if(bestNodeInfo.node === null || node.boundSize <= bestNodeInfo.boundSize){
                        bestNodeInfo.node = node;
                        bestNodeInfo.boundSize = node.boundSize;
                    }
                }
            }
        }
        function getNodeXPath(node){
            var XPath = '', index;
            while(node){
                var attrName, attrValue;
                for(var i=0;i<arrKeyAttrs.length;i++){
                    attrName = arrKeyAttrs[i];
                    attrValue = node[attrName];
                    if(attrValue && mapNodeValueCount[attrName][attrValue] === 1){
                        XPath = '/*[@'+attrName+'="'+attrValue+'"]' + XPath;
                        return '/'+XPath;
                    }
                }
                index = getNodeClassIndex(node)
                XPath = '/' + node['class'] + (index > 1 ? '['+index+']' : '') + XPath;
                node = node.parentNode;
            }
            return '/'+XPath;
        }
        function getNodeClassIndex(node){
            var index = 0;
            var className = node.class;
            var parentNode = node.parentNode;
            if(className && parentNode && Array.isArray(parentNode.node) && parentNode.node.length > 1){
                var childNodes = parentNode.node, childNode;
                index = -1;
                for(var i=0;i<childNodes.length;i++){
                    childNode = childNodes[i];
                    if(childNode.class === className){
                        index ++;
                        if(childNode === node){
                            break;
                        }
                    }
                }
            }
            return index + 1;
        }

        // 计算字节长度,中文两个字节
        function byteLen(text) {
            var count = 0;
            for (var i = 0, len = text.length; i < len; i++) {
                char = text.charCodeAt(i);
                count += char > 255 ? 2 : 1;
            }
            return count;
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

        function request_get() {
            sourceSaveCommand('getSource');
        }

        function sourceSaveCommand(cmd, data) {
            var cmdData = {
                cmd: cmd,
                data: data
            };

            var data = {
                type: 'command',
                data: cmdData
            };
            sourceSocket.send(JSON.stringify(data));

        }

        var socket = new WebSocket('ws://localhost:9765');

        var sourceSocket = new WebSocket('ws://localhost:9766');

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

            sourceSocket.onopen=function (event) {
                sourceSocket.onmessage = function (event) {
                    console.log('Client received a message', event);

                    var appInfo = JSON.parse(event.data);
                    var appSource = appInfo.source;

                    appTree = appSource.tree || appSource.hierarchy.node;
                    scanAllNode();
                };
            };

            setInterval("request_get()", 500);//1000为1秒钟


            $('#screenshot').click(function (event) {
                var upX = event.offsetX, upY = event.offsetY;

                if (Math.abs(downX - upX) < 20 && Math.abs(downY - upY) < 20) {

                    var cmdData = getNodeInfo(Math.floor(upX * scaleX), Math.floor(upY * scaleY));


                    saveCommand('click', {
                        touchX: Math.floor(upX * scaleX),
                        touchY: Math.floor(upY * scaleY)
                    });

                    var str;
                    if(cmdData.path){
                        str = "\nit('click "+cmdData.path+" ', function () {\n"+
                            "\treturn \n"+
                            "\tdriver.elementByXPath('"+cmdData.path+"')"+
                            "\t.click().sleep(1000);\n"+
                            "\t});\n";
                    }else if(cmdData.text){
                        str = "\nit('click "+cmdData.path+" ', function () {\n"+
                            "\treturn  \n"+
                            "\tdriver \n"+
                            "\t.elementByName('"+cmdData.path+"')"+
                            "\t.click()\n"+".sleep(1000);\n"+
                            "\t});\n";
                    }else{
                        str = "\nit('click ("+Math.floor(upX * scaleX)+","+Math.floor(upY * scaleY)+") ', function () {\n"+
                            "\treturn \n"+
                            "\tdriver \n"+
                            "\t.touch('tap',{\n"+
                            "\t\tx:"+Math.floor(upX * scaleX)+",\n"+
                            "\t\ty:"+Math.floor(upY * scaleY)+"\n"+"})"+
                            "\t.sleep(1000);\n"+
                            "\t});\n";
                    }

//                    alert(str);
                    editor.getModel().setValue(editor.getModel().getValue()+str);


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

                    var str = "\nit('swipe', function () {\n"+
                        "\treturn driver.touch('drag', {\n"+
                        "\t\tfromX:"+ Math.floor(downX * scaleX)+",\n"+
                        "\t\tfromY:"+ Math.floor(downY * scaleY)+",\n"+
                        "\t\ttoX:"+ Math.floor(upX * scaleX)+",\n"+
                        "\t\ttoY:"+ Math.floor(upY * scaleY)+",\n"+
                        "\t\tduration: 1\n"+
                        "\t}).sleep(1000);\n"+
                        "});\n";

//                    alert(str);
                    editor.getModel().setValue(editor.getModel().getValue()+str);

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


<%--<div style="text-align: center">--%>
    <%--<p>--%>
        <%--<button type="button" onclick="clickFunc('menu')" class="btn btn-sm btn-info">menu</button>--%>
        <%--<button type="button" onclick="clickFunc('home')" class="btn btn-sm btn-info">home</button>--%>
        <%--<button type="button" onclick="clickFunc('back')" class="btn btn-sm btn-info">back</button>--%>
    <%--</p>--%>
    <%--<img id="screenshot" class="img-thumbnail" data-holder-rendered="true">--%>
<%--</div>--%>

<div style="text-align: center">
    <table>

        <tr>
            <p>
                <button type="button" onclick="clickFunc('menu')" class="btn btn-sm btn-info">menu</button>
                <button type="button" onclick="clickFunc('home')" class="btn btn-sm btn-info">home</button>
                <button type="button" onclick="clickFunc('back')" class="btn btn-sm btn-info">back</button>
                <button type="button" onclick="clickFunc('record')" class="btn btn-sm btn-info">录制</button>
            </p>

        </tr>

        <tr>

            <td style="padding-left: 50px">

                <img id="screenshot" style="width:400px;height:600px;border:1px;float:left;" data-holder-rendered="true">

            </td>
            <td style="padding-left: 10px;">
                <div id="container" style="width:750px;height:600px;border:1px solid grey;float:right"></div>


                <script type="text/javascript"  src="monaco-editor/min/vs/loader.js"></script>
                <script>
                    require.config({ paths: { 'vs': 'monaco-editor/min/vs' }});
                    require(['vs/editor/editor.main'], function() {
                        editor = monaco.editor.create(document.getElementById('container'), {
                            value: '',
                            language: 'javascript'
                        });
                    });
                </script>

            </td>
        </tr>
    </table>



</div>

<div>


</div>

</body>
</html>
