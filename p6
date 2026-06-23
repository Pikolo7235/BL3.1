// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

interface ISubmission {
    event RecordAdded(address indexed user, bytes32 indexed albumHash, string albumName);
    event FavoritesReset(address indexed user);

    function getApprovedRecords() external view returns (string[] memory);
    function addRecord(string memory _albumName) external;
    function getUserFavorites(address _address) external view returns (string[] memory);
    function resetUserFavorites() external;
}

contract Submission is ISubmission {
    // Custom Errors - oszczędność gazu przy revertach
    error AlbumNotApproved();
    error AlreadyInFavorites();

    // Mapowania O(1) dla minimalnego zużycia gazu
    mapping(bytes32 => bool) private approvedRecords;
    mapping(address => string[]) private userFavorites;
    
    // Zabezpieczenie przed duplikatami: użytkownik => hash albumu => czy jest ulubiony
    mapping(address => mapping(bytes32 => bool)) private isFavorite;

    // Konstruktor uruchamiany raz przy wdrożeniu – oszczędza gaz użytkowników
    constructor() {
        bytes32[] memory approved = new bytes32[](9);
        approved[0] = keccak256("Boss");
        approved[1] = keccak256("Mona");
        approved[2] = keccak256("Kirk");
        approved[3] = keccak256("Yes to");
        approved[4] = keccak256("To the Moon");
        approved[5] = keccak256("Hassan");
        approved[6] = keccak256("Pocket");
        approved[7] = keccak256("Pikolo");
        approved[8] = keccak256("Kosynier");

        unchecked {
            for (uint256 i = 0; i < approved.length; i++) {
                approvedRecords[approved[i]] = true;
            }
        }
    }

    // Wywoływane rzadko (np. przez frontend) – koszt gazu nie jest tu priorytetem
    function getApprovedRecords() external pure override returns (string[] memory) {
        string[] memory approved = new string[](9);
        approved[0] = "Boss";
        approved[1] = "Mona";
        approved[2] = "Kirk";
        approved[3] = "Yes to";
        approved[4] = "To the Moon";
        approved[5] = "Hassan";
        approved[6] = "Pocket";
        approved[7] = "Pikolo";
        approved[8] = "Kosynier";
        return approved;
    }

    // Funkcja zoptymalizowana pod kątem gazu z blokadą duplikatów O(1)
    function addRecord(string calldata _albumName) external override {
        bytes32 albumHash = keccak256(abi.encodePacked(_albumName));
        
        // 1. Sprawdzenie czy album w ogóle istnieje na białej liście
        if (!approvedRecords[albumHash]) {
            revert AlbumNotApproved();
        }

        // 2. Ochrona przed duplikatami w czasie O(1)
        if (isFavorite[msg.sender][albumHash]) {
            revert AlreadyInFavorites();
        }

        // 3. Zapis danych i flagi
        isFavorite[msg.sender][albumHash] = true;
        userFavorites[msg.sender].push(_albumName);

        emit RecordAdded(msg.sender, albumHash, _albumName);
    }

    // Funkcja widokowa (view) dla frontendu - darmowa przy wywołaniach RPC
    function getUserFavorites(address _address) external view override returns (string[] memory) {
        return userFavorites[_address];
    }

    // Czyszczenie danych w celu zwrotu gazu (Gas Refund) oraz reset flag duplikatów
    function resetUserFavorites() external override {
        // Czyszczenie flag isFavorite dla każdego albumu z listy użytkownika
        string[] memory favorites = userFavorites[msg.sender];
        uint256 length = favorites.length;
        
        unchecked {
            for (uint256 i = 0; i < length; i++) {
                bytes32 albumHash = keccak256(abi.encodePacked(favorites[i]));
                delete isFavorite[msg.sender][albumHash];
            }
        }

        // Usunięcie samej tablicy z pamięci masowej (storage)
        delete userFavorites[msg.sender];
        
        emit FavoritesReset(msg.sender);
    }
}
