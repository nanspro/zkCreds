pragma solidity >=0.5.0 <0.6.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "@aztec/protocol/contracts/ERC1724/ZkAssetMintable.sol";
import "@aztec/protocol/contracts/ERC1724/ZkAsset.sol";
import "@aztec/protocol/contracts/ACE/ACE.sol";
import "@aztec/protocol/contracts/ERC20/ERC20Mintable.sol";
import "@aztec/protocol/contracts/libs/ProofUtils.sol";
import "@aztec/protocol/contracts/ACE/validators/privateRange/PrivateRange.sol";


// Annual Salary in rs (rounding off to nearest integer)
contract ISalary is ZkAssetMintable {
    // event UpdateTotalMinted(bytes32 noteHash, bytes noteData);
    address public salaryAddr;

    constructor(
        address _aceAddress,
        address _linkedTokenAddress,
        uint256 _scalingFactor
    ) public ZkAssetMintable(
        _aceAddress,
        _linkedTokenAddress,
        _scalingFactor
    ) {
        salaryAddr = msg.sender;
    }

    function register(uint24 _proof, bytes calldata _proofData) external {
        require(msg.sender == salaryAddr, "only the owner can register others");
        require(_proofData.length != 0, "proof invalid");

        (bytes memory _proofOutputs) = ace.mint(_proof, _proofData, address(this));

        (, bytes memory newTotal, ,) = _proofOutputs.get(0).extractProofOutput();

        (, bytes memory mintedNotes, ,) = _proofOutputs.get(1).extractProofOutput();

        (,
        bytes32 noteHash,
        bytes memory metadata) = newTotal.get(0).extractNote();

        logOutputNotes(mintedNotes);
        emit UpdateTotalMinted(noteHash, metadata);
    }

    // function validateOwnership(bytes32 _message, bytes calldata _signature, bytes32 _noteHash) external returns (bool) {
    function validateOwnership(bytes32 _message, uint8 v, bytes32 r, bytes32 s, bytes32 _noteHash) external view returns (bool) {
        (, , , address noteOwner ) = ace.getNote(address(this), _noteHash);
        address signer = ecrecover(_message, v, r, s);
        // address signer = recoverSignature(_message, _signature);
        if (signer == noteOwner) {
            return true;
        }
        else return false;
    }

    function validateRange(uint24 _proof, bytes calldata _proofData) external {
        ace.validateProof(_proof, msg.sender, _proofData);
    }

    function validateRatio(uint24 _proof, bytes calldata _proofData) external {
        ace.validateProof(_proof, msg.sender, _proofData);
    }
}