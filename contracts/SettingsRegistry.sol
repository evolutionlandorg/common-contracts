pragma solidity ^0.4.24;

import "./interfaces/ISettingsRegistry.sol";
import "./DSAuth.sol";

/**
 * @title SettingsRegistry
 * @dev This contract holds all the settings for updating and querying.
 */
contract SettingsRegistry is ISettingsRegistry, DSAuth {

    mapping(bytes32 => uint256) public uintProperties;
    mapping(bytes32 => string) public stringProperties;
    mapping(bytes32 => address) public addressProperties;
    mapping(bytes32 => bytes) public bytesProperties;
    mapping(bytes32 => bool) public boolProperties;
    mapping(bytes32 => int256) public intProperties;

    mapping(bytes32 => SettingsValueTypes) public valueTypes;

    function uintOf(bytes32 _propertyName) public view returns (uint256) {
        require(valueTypes[_propertyName] == SettingsValueTypes.UINT, "Property type does not match.");
        return uintProperties[_propertyName];
    }

    function stringOf(bytes32 _propertyName) public view returns (string) {
        require(valueTypes[_propertyName] == SettingsValueTypes.STRING, "Property type does not match.");
        return stringProperties[_propertyName];
    }

    function addressOf(bytes32 _propertyName) public view returns (address) {
        require(valueTypes[_propertyName] == SettingsValueTypes.ADDRESS, "Property type does not match.");
        return addressProperties[_propertyName];
    }

    function bytesOf(bytes32 _propertyName) public view returns (bytes) {
        require(valueTypes[_propertyName] == SettingsValueTypes.BYTES, "Property type does not match.");
        return bytesProperties[_propertyName];
    }

    function boolOf(bytes32 _propertyName) public view returns (bool) {
        require(valueTypes[_propertyName] == SettingsValueTypes.BOOL, "Property type does not match.");
        return boolProperties[_propertyName];
    }

    function intOf(bytes32 _propertyName) public view returns (int) {
        require(valueTypes[_propertyName] == SettingsValueTypes.INT, "Property type does not match.");
        return intProperties[_propertyName];
    }

    function setUintProperty(bytes32 _propertyName, uint _value) public auth {
        require(
            valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.UINT, "Property type does not match.");
        uintProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.UINT;

        emit ChangeProperty(_propertyName, uint256(SettingsValueTypes.UINT));
    }

    function setStringProperty(bytes32 _propertyName, string _value) public auth {
        require(
            valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.STRING, "Property type does not match.");
        stringProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.STRING;

        emit ChangeProperty(_propertyName, uint256(SettingsValueTypes.STRING));
    }

    function setAddressProperty(bytes32 _propertyName, address _value) public auth {
        require(
            valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.ADDRESS, "Property type does not match.");

        addressProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.ADDRESS;

        emit ChangeProperty(_propertyName, uint256(SettingsValueTypes.ADDRESS));
    }

    function setBytesProperty(bytes32 _propertyName, bytes _value) public auth {
        require(
            valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.BYTES, "Property type does not match.");

        bytesProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.BYTES;

        emit ChangeProperty(_propertyName, uint256(SettingsValueTypes.BYTES));
    }

    function setBoolProperty(bytes32 _propertyName, bool _value) public auth {
        require(
            valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.BOOL, "Property type does not match.");

        boolProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.BOOL;

        emit ChangeProperty(_propertyName, uint256(SettingsValueTypes.BOOL));
    }

    function setIntProperty(bytes32 _propertyName, int _value) public auth {
        require(
            valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.INT, "Property type does not match.");

        intProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.INT;

        emit ChangeProperty(_propertyName, uint256(SettingsValueTypes.INT));
    }

    function getValueTypeOf(bytes32 _propertyName) public view returns (uint256 /* SettingsValueTypes */ ) {
        return uint256(valueTypes[_propertyName]);
    }

}