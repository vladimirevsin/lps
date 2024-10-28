import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Control
import QtQuick.Effects
import Linphone
import UtilsCpp
import SettingsCpp

Item{
    
    id: callManager 
    anchors.bottom: parent.bottom
    anchors.bottomMargin:100
    anchors.topMargin:100
    anchors.leftMargin:100
    anchors.rightMargin:100
    anchors.verticalCenter:parent.verticalCenter
    property  string pressedColor:"#00ffff"
    property FriendGui currentContact
    property var call;
    property int currentLine: 1
    property int countCalls:0;
    property var callState: call ? call.core.state : LinphoneEnums.CallState.Idle
    property bool callInProgres: false
    property var transferState: call ? call.core.transferState : null
    property bool callTerminatedByUser: false
    property string timerLine1: ""
    property string timerLine2: ""
    
    
    function getColorCallButton() {
        if (callManager.callInProgres) {
            return "red";
        }
        return "green";
    }

    function setState(newState) {
        callManager.callState = newState;
        callManager.callInProgres = newState !== LinphoneEnums.CallState.Idle && newState !== LinphoneEnums.CallState.Released;
        UtilsCpp.showInformationPopup("State Changed", currentCall.core.state, false);
        referencetext3.text=qsTr("state: %1").arg(callState);
    }

    function setTimer(newTimerData) {
        if (callManager.currentLine === 1) {
            callManager.timerLine1 = newTimerData;
            return;
        } 

        if (callManager.currentLine === 2) {
            callManager.timerLine2 = newTimerData;
            return;
        }
    }

    function endCall() {
        if (callManager.currentLine === 1) {
            callManager.timerLine1 = "";
            return;
        } 

        if (callManager.currentLine === 2) {
            callManager.timerLine2 = "";
            return;
        }

    }
    
    CallProxy {
        id: callsModel
        sourceModel: AppCpp.calls

        onCurrentCallChanged: {
            if(currentCall) {
                callManager.call = currentCall;
                
                currentCall.core.stateChanged.connect(function(newState) {
                    callManager.setState(newState);
                });
                currentCall.core.callTimerChanged.connect(function() {
                    setTimer(currentCall.core.callTimer);
                });
                
                currentCall.core.lSetPaused(false);
            }
        }
        onHaveCallChanged: {
            callManager.callInProgress = haveCall;
            
            if (!haveCall) {
                callManager.endCall()
            }
        }
        onCountChanged: {
            callManager.countCalls = count

            bk1.color = callManager.countCalls == 0 ? "gray" : "lightgreen"
            bk2.color = callManager.countCalls > 1 ? "lightgreen" : "gray"
            callManager.currentCall = count > 0 ? count - 1 : 1
        }
    }
    
    onCallStateChanged: {
        UtilsCpp.showInformationPopup("State Changed", currentCall.core.state, false);
    }
    
    Connections {
        enabled: !!call
        target: call && call.core
        function onSecurityUpdated() {
            if (call.core.encryption === LinphoneEnums.MediaEncryption.Zrtp) {
                if (call.core.tokenVerified) {
                    zrtpValidation.close()
                    zrtpValidationToast.open()
                } else {
                    zrtpValidation.open()
                }
            } else {
                zrtpValidation.close()
            }
        }
        function onTokenVerified() {
            if (!zrtpValidation.isTokenVerified) {
                zrtpValidation.securityError = true
            } else zrtpValidation.close()
        }
    }
    
    // Вызываем или завершаем звонок в зависимости от состояния
    function callCurrentContact() {
        if (callManager.callState !== LinphoneEnums.CallState.Idle && callManager.callState !== LinphoneEnums.CallState.Released) {
            if (call) {
                call.core.lTerminate()
            }
        } else {
            if (currentContact) {
                UtilsCpp.showInformationPopup("callCurrentContact",currentContact.core.defaultAddress, false);

                UtilsCpp.createCall(currentContact.core.defaultAddress)
            } else {
                console.log("Нет выбранного контакта для звонка")
            }
        }
    }
    
    // Удержание или возобновление звонка
    function toggleHold() {
        if (callManager.call) {
            if (callManager.callState === LinphoneEnums.CallState.Paused) {
                callManager.call.core.lSetPaused(false)
            } else {
                callManager.call.core.lSetPaused(true)
            }
        }
    }
    
    function handleCall(lineNumber) {
        if (callManager.countCalls >= lineNumber) {
            if (callManager.currentLine !== lineNumber) {
                callManager.call.core.lSetPaused(true);
            }
            callsModel.currentCall = callsModel.getAt(callManager.countCalls - lineNumber);
            
        } else {
            callManager.callInProgres = false;
            callManager.callState = LinphoneEnums.CallState.Idle;
        }

        callManager.currentLine = lineNumber;
    }
    
    
    // Трансфер звонка
    function transferCallToContact() {
        if (currentContact)
            call.core.lTransferCall(currentContact.core.defaultAddress)
    }

    // нулевой RowLayout
    RowLayout {
        spacing: 20
        anchors.horizontalCenter:parent.horizontalCenter
        anchors.top:parent.top
        Rectangle { 
            id:reference1
            width:200
            height:30
            anchors.top:parent.top
            color: mainWindow.color
            Text {
                id:referencetext
                font.pixelSize:25
                anchors.top:parent.top 
                text: qsTr("Каналов " )+callManager.countCalls
            }
        }
        
        Rectangle { 
            id:reference2
            width:200
            height:30
            anchors.top:parent.top
            color: mainWindow.color 
            Text {
                id:referencetext2
                font.pixelSize:25
                anchors.top:parent.top 
                text:qsTr("Линия: ")
            }
        }
        
        Rectangle { 
            id:reference3
            width:200
            height:30
            anchors.top:parent.top
            color:mainWindow.color //"red"
            Text {
                id:referencetext3
                font.pixelSize:25
                anchors.top:parent.top 
                text: qsTr("Состояние: %1").arg(callState)
            }
        }
        
    }

    ColumnLayout {
        id:column1
        
        anchors.top:parent.top
        anchors.topMargin:mainWindow.height-column1.height -120
        anchors.horizontalCenter:parent.horizontalCenter
        
        //  anchors.centerIn:parent
        // width:parent.width-300
        //   width:callManager.width
        width:mainWindow.width*0.9
        
        spacing: 20
        
        // Первый RowLayout
        RowLayout {
            spacing: 20
            anchors.horizontalCenter:parent.horizontalCenter
            
            Control.Button {
                id:linia1
                text: qsTr("1 линия %1").arg(callManager.timerLine1)
                font.pixelSize:15
                font.bold:true
                
                enabled: countCalls > 0
                background: Rectangle {
                    id:bk1
                    radius: 8
                    color:"gray"
                }
                onClicked: {
                    handleCall(1);
                    referencetext2.text="Линия 1"
                }
            }
            
            Control.Button {
                id:linia2
                
                enabled: countCalls > 0
                
                text: qsTr("2 линия %1").arg(callManager.timerLine2)
                font.pixelSize:15
                font.bold:true
                
                background: Rectangle {
                    id:bk2    
                    radius: 8
                    color:"gray"
                }
                onClicked: {
                    handleCall(2);
                    referencetext2.text="Линия 2"
                }
            }
            
        }
        
        // Второй RowLayout (Кнопки управления)
        RowLayout {
            spacing: 20
            anchors.horizontalCenter:parent.horizontalCenter
            
            // Кнопка удержания звонка
            Rectangle { 
                //  anchors.fill: parent
                id:rectHold
                visible: countCalls>0
                width: 49
                height: 47 * DefaultStyle.dp // 100
                color:"#00aaaa"
                radius:12
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    opacity: 1.0
                    onEntered:{
                        //  holdbutton.highlighted=true
                        holdbutton.icon.color="red"
                    }
                    onExited:{
                        //    holdbutton.highlighted=false
                        holdbutton.icon.color="black"
                    }
                    Control.Button {
                        id:holdbutton
                        visible: countCalls>0  //callManager.callInProgress
                        icon.source: callManager.callState === LinphoneEnums.CallState.Paused ? AppIcons.play : AppIcons.pause
                        icon.width: 32 * DefaultStyle.dp
                        icon.height: 32 * DefaultStyle.dp
                        icon.color:"black"
                        background: Rectangle {
                            radius: 8
                        }
                        onPressed:
                        { 
                            holdbutton.highlighted=true
                            icon.color= pressedColor
                        }
                        onClicked: {
                            callManager.toggleHold()
                            icon.color="black"
                            holdbutton.highlighted=false
                        }
                    }
                }
            } //end rectHold
            
            // Кнопка трансфера звонка
            
            Rectangle { 
                //  anchors.fill: parent
                visible: countCalls > 0
                id:rectTrans
                width: 50
                height: 47 * DefaultStyle.dp // 100
                color:"#00aaaa"
                radius:12
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    opacity: 1.0
                    onEntered:{
                        //referencetext.text="Нажата  тестовая кнопка"
                        transbutton.highlighted=true
                    }
                    onExited:{
                        //referencetext.text="отпущена  тестовая кнопка"
                        tansbutton.highlighted=false
                    }
                    Control.Button {
                        id:transbutton
                        visible: true // countCalls>0 //callManager.callInProgress
                        icon.source: AppIcons.transferCall
                        Layout.preferredWidth: 55 * DefaultStyle.dp
                        Layout.preferredHeight: 55 * DefaultStyle.dp
                        icon.width: 32 * DefaultStyle.dp
                        icon.height: 32 * DefaultStyle.dp
                        background: Rectangle {
                            id:backgrtrans
                            color: "blue"
                            radius: 8
                        }
                        onPressed: {
                            transbutton.highlighted=true
                            backgrtrans.color= pressedColor
                        }
                        
                        onClicked: {
                            callManager.transferCallToContact()
                            backgrtrans.color= "blue"
                            transbutton.highlighted=false
                        }
                    }
                }
            }
            
            Control.Button {
                id:test1
                visible:false
                icon.source:  AppIcons.endCall
                Layout.preferredWidth: 55 * DefaultStyle.dp
                Layout.preferredHeight: 55 * DefaultStyle.dp
                icon.width: 32 * DefaultStyle.dp
                icon.height: 32 * DefaultStyle.dp
                
                background: Rectangle {
                    id:r1
                    color:callManager.testColor
                    radius: 8
                }
                onPressed:
                { 
                    referencetext.text="Нажата  тестовая кнопка"
                    //callManager.testColor="#000000"
                    test1.highlighted=true
                    // test1.flat=true
                    r1.color="red"
                }
                onClicked: {
                    referencetext.text="Отпущена  тестовая кнопка"
                    //   mainWindow.endCall(modelData)
                    //test1.color="green"
                    // test1.flat=false
                    
                    test1.highlighted=false
                    
                }
            }
            
            // Кнопка микрофона
            CheckableButton {
                id:mikrbutton
                iconUrl: AppIcons.microphone
                visible: countCalls>0 
                checkedIconUrl: AppIcons.microphoneSlash
                checked: callManager.call && callManager.call.core.microphoneMuted
                Layout.preferredWidth: 55 * DefaultStyle.dp
                Layout.preferredHeight: 55 * DefaultStyle.dp
                icon.width: 32 * DefaultStyle.dp
                icon.height: 32 * DefaultStyle.dp
                onClicked:
                {  mikrbutton.highlighted=false        
                    callManager.call.core.lSetMicrophoneMuted(!callManager.call.core.microphoneMuted)
                }
            }
            
        }
        //Третий RowLayout (Кнопки управления)
        RowLayout {
            id:layout3
            anchors.horizontalCenter:parent.horizontalCenter
            
            spacing: 20
            
            Rectangle { // Кнопка вызова/завершения звонка
                id:rectCall
                
                implicitWidth: column1.width
                height: 48 * DefaultStyle.dp // 100
                color:"#00aaaa"
                radius:12
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    opacity: 1.0
                    onEntered:{
                        b1.highlighted=true
                    }
                    onExited:{
                        b1.highlighted=false
                    }
                    
                    Control.Button {
                        id:b1
                        anchors.horizontalCenter:parent.horizontalCenter
                        anchors.verticalCenter:parent.verticalCenter
                        width:column1.width   
                        icon.source: callManager.callState === LinphoneEnums.CallState.Idle || callManager.callState === LinphoneEnums.CallState.Released ? AppIcons.phone : AppIcons.endCall
                        icon.width: 32 * DefaultStyle.dp
                        icon.height: 32 * DefaultStyle.dp
                        background: Rectangle {
                            id:backgroundCall
                            color: callManager.callState === LinphoneEnums.CallState.Idle || callManager.callState === LinphoneEnums.CallState.Released ? DefaultStyle.success_500main : DefaultStyle.danger_500main
                            radius: 10
                        }
                        onPressed: {
                            //highlighted = true
                        }
                        onClicked: {
                            //highlighted=false
                            callManager.callCurrentContact()
                        }
                    }
                }
            } //end  rectCall
        }
        
    }
} //endItem
