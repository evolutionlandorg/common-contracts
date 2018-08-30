pragma solidity ^0.4.24;

import './interfaces/ISettingsRegistry.sol';
import './RBACWithAuth.sol';

/**
 * @title SettingsRegistry
 * @dev This contract holds all the settings for updating and querying.
 */
contract SettingsRegistry is ISettingsRegistry, RBACWithAuth {
    mapping(bytes32 => uint256) public uintProperties;
    mapping(bytes32 => string) public stringProperties;
    mapping(bytes32 => address) public addressProperties;
    mapping(bytes32 => bytes) public bytesProperties;
    mapping(bytes32 => bool) public boolProperties;
    mapping(bytes32 => int256) public intProperties;

    mapping(bytes32 => SettingsValueTypes) public valueTypes;


    // TODO: add events.

    function uintOf(bytes32 _propertyName) public view returns (uint256) {
        require(valueTypes[_propertyName] == SettingsValueTypes.UINT);
        return uintProperties[_propertyName];
    }

    function stringOf(bytes32 _propertyName) public view returns (string) {
        require(valueTypes[_propertyName] == SettingsValueTypes.STRING);
        return stringProperties[_propertyName];
    }

    function addressOf(bytes32 _propertyName) public view returns (address) {
        require(valueTypes[_propertyName] == SettingsValueTypes.ADDRESS);
        return addressProperties[_propertyName];
    }

    function bytesOf(bytes32 _propertyName) public view returns (bytes) {
        require(valueTypes[_propertyName] == SettingsValueTypes.BYTES);
        return bytesProperties[_propertyName];
    }

    function boolOf(bytes32 _propertyName) public view returns (bool) {
        require(valueTypes[_propertyName] == SettingsValueTypes.BOOL);
        return boolProperties[_propertyName];
    }

    function intOf(bytes32 _propertyName) public view returns (int) {
        require(valueTypes[_propertyName] == SettingsValueTypes.INT);
        return intProperties[_propertyName];
    }

    function setUintProperty(bytes32 _propertyName, uint _value) public isAuth {
        require(valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.UINT);
        uintProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.UINT;
    }

    function setStringProperty(bytes32 _propertyName, string _value) public isAuth {
        require(valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.STRING);
        stringProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.STRING;
    }

    function setAddressProperty(bytes32 _propertyName, address _value) public isAuth {
        require(valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.ADDRESS);
        addressProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.ADDRESS;
    }

    function setBytesProperty(bytes32 _propertyName, bytes _value) public isAuth {
        require(valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.BYTES);
        bytesProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.BYTES;
    }

    function setBoolProperty(bytes32 _propertyName, bool _value) public isAuth {
        require(valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.BOOL);
        boolProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.BOOL;
    }

    function setIntProperty(bytes32 _propertyName, int _value) public isAuth {
        require(valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.INT);
        intProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.INT;
    }

    function getValueTypeOf(bytes32 _propertyName) public view returns (uint /* SettingsValueTypes */ ) {
        return uint(valueTypes[_propertyName]);
    }

}