/*
 * Copyright 2019 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.mobileer.oboetester;

import android.annotation.TargetApi;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.AudioDeviceCallback;
import android.media.AudioDeviceInfo;
import android.media.AudioManager;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import com.mobileer.audio_device.AudioDeviceInfoConverter;

import java.io.IOException;
import java.util.HashMap;

/**
 * Tests the latency of plugging in or unplugging an audio device.
 */
public class TestPlugLatencyActivity extends TestAudioActivity {

    public static final int POLL_DURATION_MILLIS = 1;

    private TextView     mInstructionsTextView;
    private TextView     mPlugTextView;
    private TextView     mAutoTextView;
    MyAudioDeviceCallback mDeviceCallback = new MyAudioDeviceCallback();
    private AudioManager mAudioManager;

    private volatile int mPlugCount = 0;

    private AudioOutputTester   mAudioOutTester;

    class MyAudioDeviceCallback extends AudioDeviceCallback {
        private HashMap<Integer, AudioDeviceInfo> mDevices
                = new HashMap<Integer, AudioDeviceInfo>();

        @Override
        public void onAudioDevicesAdded(AudioDeviceInfo[] addedDevices) {
            boolean isBootingUp = mDevices.isEmpty();
            for (AudioDeviceInfo info : addedDevices) {
                mDevices.put(info.getId(), info);
                if (!isBootingUp)
                {
                    log("Device Added");
                    log(adiToString(info));
                }

            }

            if (isBootingUp) {
                log("Starting stream with existing audio devices");
            }
            updateLatency(false /* wasDeviceRemoved */);
        }

        public void onAudioDevicesRemoved(AudioDeviceInfo[] removedDevices) {
            for (AudioDeviceInfo info : removedDevices) {
                mDevices.remove(info.getId());
                log("Device Removed");
                log(adiToString(info));
            }

            updateLatency(true /* wasDeviceRemoved */);
        }
    }

    @Override
    protected void inflateActivity() {
        setContentView(R.layout.activity_test_plug_latency);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        mInstructionsTextView = (TextView) findViewById(R.id.text_instructions);
        mPlugTextView = (TextView) findViewById(R.id.text_plug_events);
        mAutoTextView = (TextView) findViewById(R.id.text_log_device_report);

        mAudioManager = (AudioManager) getSystemService(Context.AUDIO_SERVICE);
    }

    @Override
    protected void onStart() {
        super.onStart();
        addAudioDeviceCallback();
    }

    @Override
    protected void onStop() {
        removeAudioDeviceCallback();
        super.onStop();
    }

    @TargetApi(23)
    private void addAudioDeviceCallback(){
        // Note that we will immediately receive a call to onDevicesAdded with the list of
        // devices which are currently connected.
        mAudioManager.registerAudioDeviceCallback(mDeviceCallback, null);
    }

    @TargetApi(23)
    private void removeAudioDeviceCallback(){
        mAudioManager.unregisterAudioDeviceCallback(mDeviceCallback);
    }

    @Override
    public String getTestName() {
        return "Plug Latency";
    }

    int getActivityType() {
        return ACTIVITY_TEST_DISCONNECT;
    }

    @Override
    boolean isOutput() {
        return true;
    }

    // Write to status and command view
    private void setInstructionsText(final String text) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mInstructionsTextView.setText(text);
            }
        });
    }

    public void startAudioTest() throws IOException {
        startAudio();
    }

    private long calculateLatencyMs(boolean wasDeviceRemoved) {

        long startMillis = System.currentTimeMillis();

        try {
            if (wasDeviceRemoved && (mAudioOutTester != null)) {
                // Keep querying as long as error is ok
                while (mAudioOutTester.getLastErrorCallbackResult() == 0) {
                    Thread.sleep(POLL_DURATION_MILLIS);
                }
                log("Error callback at " + (System.currentTimeMillis() - startMillis) + " ms");
            }
            closeAudio();
            log("Audio closed at " + (System.currentTimeMillis() - startMillis) + " ms");
            clearStreamContexts();
            mAudioOutTester = addAudioOutputTester();
            openAudio();
            log("Audio opened at " + (System.currentTimeMillis() - startMillis) + " ms");
            AudioStreamBase stream = mAudioOutTester.getCurrentAudioStream();
            startAudioTest();
            log("Audio starting at " + (System.currentTimeMillis() - startMillis) + " ms");
            while (stream.getState() == StreamConfiguration.STREAM_STATE_STARTING) {
                Thread.sleep(POLL_DURATION_MILLIS);
            }
            log("Audio started at " + (System.currentTimeMillis() - startMillis) + " ms");
            while (mAudioOutTester.getFramesRead() == 0) {
                Thread.sleep(POLL_DURATION_MILLIS);
            }
            log("First frame read at " + (System.currentTimeMillis() - startMillis) + " ms");
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
            return -1;
        }

        return System.currentTimeMillis() - startMillis;
    }

    public static String adiToString(AudioDeviceInfo adi) {

        StringBuilder sb = new StringBuilder();
        sb.append("Id: ");
        sb.append(adi.getId());

        sb.append("\nProduct name: ");
        sb.append(adi.getProductName());

        sb.append("\nType: ");
        sb.append(AudioDeviceInfoConverter.typeToString(adi.getType()));

        return sb.toString();
    }

    // Write to scrollable TextView
    private void log(final String text) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mAutoTextView.append(text);
                mAutoTextView.append("\n");
            }
        });
    }

    private void updateLatency(boolean wasDeviceRemoved) {
        mPlugCount++;
        log("\nOperation #" + mPlugCount + " starting");
        long latencyMs = calculateLatencyMs(wasDeviceRemoved);
        String message = "Operation #" + mPlugCount + " latency: "+ latencyMs + " ms\n";
        log(message);
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mPlugTextView.setText(message);
            }
        });
    }
}
