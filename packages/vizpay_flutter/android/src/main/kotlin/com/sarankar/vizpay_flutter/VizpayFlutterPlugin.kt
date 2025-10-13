package com.sarankar.vizpay_flutter

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class VizpayFlutterPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var pendingResult: MethodChannel.Result? = null

    private val REQUEST_CODE_SALE = 101
    private val PACKAGE_NAME = "com.icici.viz.verifone"
    private val SALE = "SALE"

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "vizpay_flutter")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener { requestCode, _, data ->
            if (requestCode == REQUEST_CODE_SALE) {
                handleSaleResponse(data)
                true
            } else {
                false
            }
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "startSaleTransaction") {
            if (activity == null) {
                result.error("NO_ACTIVITY", "Plugin not attached to an Activity", null)
                return
            }
            pendingResult = result
            startSale(call.arguments as Map<*, *>)
        } else {
            result.notImplemented()
        }
    }

    private fun startSale(args: Map<*, *>) {
        try {
            val amount = args["amount"] as String
            val billNumber = args["billNumber"] as String
            val sourceId = args["sourceId"] as String
            val tipAmount = args["tipAmount"] as? String ?: ""
            val printFlag = args["printFlag"] as String

            val saleRequest = JSONObject()
            saleRequest.put("AMOUNT", amount)
            saleRequest.put("TIP_AMOUNT", tipAmount)
            saleRequest.put("TRAN_TYPE", SALE)
            saleRequest.put("BILL_NUMBER", billNumber)
            saleRequest.put("PRINT_FLAG", printFlag)
            saleRequest.put("SOURCE_ID", sourceId)
            saleRequest.put("UDF1", "")
            saleRequest.put("UDF2", "")
            saleRequest.put("UDF3", "")
            saleRequest.put("UDF4", "")
            saleRequest.put("UDF5", "")

            Log.d("VizpayFlutter", "Sale Request: $saleRequest")

            val intent = activity!!.packageManager.getLaunchIntentForPackage(PACKAGE_NAME)
            if (intent == null) {
                pendingResult?.error("APP_NOT_INSTALLED", "ICICI Verifone app not installed", null)
                pendingResult = null
                return
            }

            intent.flags = 0
            intent.putExtra("REQUEST_TYPE", SALE)
            intent.putExtra("DATA", saleRequest.toString())

            activity!!.startActivityForResult(intent, REQUEST_CODE_SALE)
        } catch (e: Exception) {
            pendingResult?.error("SALE_ERROR", e.localizedMessage, null)
            pendingResult = null
        }
    }

    private fun handleSaleResponse(data: Intent?) {
        try {
            val bundle: Bundle? = data?.extras
            val resultJson = JSONObject(bundle?.getString("RESULT") ?: "{}")

            Log.d("VizpayFlutter", "Sale Response: $resultJson")

            val responseMap = mutableMapOf<String, Any?>()
            responseMap["RESPONSE_TYPE"] = resultJson.optString("RESPONSE_TYPE")
            responseMap["STATUS_CODE"] = resultJson.optString("STATUS_CODE")
            responseMap["STATUS_MSG"] = resultJson.optString("STATUS_MSG")
            responseMap["RECEIPT_DATA"] = resultJson.optString("RECEIPT_DATA")

            pendingResult?.success(responseMap)
        } catch (e: Exception) {
            pendingResult?.error("RESPONSE_ERROR", e.localizedMessage, null)
        } finally {
            pendingResult = null
        }
    }
}