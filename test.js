/**
 * Copyright (c) 2018 Xiamen Yaji Software Co.Ltd. All rights reserved.
 * Created by lizhiyi on 2018/10/25.
 */


var constants = require('./../shared/constants');
var _ = require('lodash');
var bclLibs = require('./../libs/bcx.min');

var CONTRACT_NAME = 'contract.tychem';

module.exports = function (app) {
    return new ModuleService(app);
};

var ModuleService = function (app) {
    this.app = app;
    this.isLoginBcl = false;
};

var moduleService = ModuleService.prototype;

moduleService.init = function () {
    var _configParams={
        api_node:{
            url:"ws://39.106.139.132:8010",
            name:"xxxxxxxx"
        },
        networks:[
        {
            core_asset:"COCOS",
            chain_id:"52e65ef663454f910ba3fe5f0b97a359f6a15aa50a329ae8de4d2b38eb0ee7a1"
        }],
        faucet_url:"http://39.106.139.132:4000",
        auto_reconnect:true,
        worker:false
        //app_keys:["5HxzZncKDjx7NEaEv989Huh7yYY7RukcJLKBDQztXAmZYCHWPgd"]
    };

    var _this = this;
    this.bcl = new BCX(_configParams);
    this.bcl.init(function (res) {
        console.log('init finish:', res);
        _this.login();
    });
};

moduleService.login = function () {
    var _this = this;
    this.bcl.passwordLogin({account: 'xxxxx', password:'xxxxxxxx',  callback: function (result) {
        _this.account = null;
        if (result.code === 1) {
            _this.isLoginBcl = true;
            _this.account = result.data.account_name;
            _this.userId = result.data.account_id;
        }
        console.log('login result', result);
    }});
};

moduleService.dice = function (roomId, roundId, objBetInfo, callback) {
    this.bcl.callContractFunction({
        nameOrId: CONTRACT_NAME,
        functionName: 'dice',//["1",1000001,'COCOS']
        valueList:[roomId + '@' + roundId, JSON.stringify(objBetInfo)],////
        callback:function(res){
            console.info("dice res",res);

            if (res.code === 1) {
                //解析结果，并直接返回开奖结果对应的数字
                var arrAffect = res.data[0].contract_affecteds;
                console.log(arrAffect);
                for (var idx = 0; idx < arrAffect.length; idx++) {
                    if (arrAffect[idx].type === "contract_affecteds_log") {
                        var text = arrAffect[idx].raw_data.message;
                        var key = "##result##:";
                        var idxFind = text.indexOf(key);
                        if (idxFind !== -1) {
                            var jsonStr = text.slice(idxFind + key.length);
                            var result = JSON.parse(jsonStr);

                            result.trx_id = res.trx_data.trx_id;

                            if (callback) {
                                callback(null, result);
                                return;
                            }
                            break;
                        }
                    }
                }

                if (callback) {
                    callback('result formate was error!', res);
                }
            } else if (callback) {
                callback(res.message, res);
            }
        }
    });
};

/**
 * 根据交易id查询玩家下注信息
 * @param {String} TXID 交易ID
 * @param {Function} callback
 */
moduleService.queryBetInfo = function (TXID, callback) {
    this.bcl.queryTransaction({
        transactionId: TXID,
        callback:function (res) {
            if (res.code !== 1) {
                callback(res.message, res);
                return;
            }

            if (!res.data || !res.data.parse_ops || !res.data.parse_ops[0]) {
                callback('result formate was error!', res);
            }

            var parse =  res.data.parse_ops[0];
            var arrAffect = parse.result.contract_affecteds;

            for (var idx = 0; idx < arrAffect.length; idx++) {
                if (arrAffect[idx].type === "contract_affecteds_log") {
                    var text = arrAffect[idx].parse_operations_text;
                    var key = "##result##:";
                    var idxFind = text.indexOf(key);

                    if (idxFind !== -1) {
                        var jsonStr = text.slice(idxFind + key.length);
                        var result = JSON.parse(jsonStr);

                        if (callback) {
                            callback(null, result);
                            return;
                        }
                        break;
                    }
                }
            }

            if (callback) {
                callback('result formate was error!', res);
            }
        },
    });
};
