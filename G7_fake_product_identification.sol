pragma solidity 0.8.0;

contract NFTgenerator {
    mapping(uint => address) owners;
    Objeto obj;
    uint id=0;
    enum ProductStatus {InProduction, ForSale, SecondHandSale, Sold}

    struct Objeto{
        string _nombre;
        uint _identificador; //Será la key del mapping de la lista objetos_reales
        uint _fechaIncorporacion;
        ProductStatus status;
    }

    constructor(){} //empty constructor

    function changeOwner(address newOwner, uint _id) internal{
        owners[_id] = newOwner;
    }

    function newNFT() internal returns(uint){
        id += 1;
        return id;
    }
}

contract ManufacturerContract is NFTgenerator {

    mapping(uint => Compra) public compras; //Lista de compras que se efectuan
    mapping(uint => Objeto) public objetos_reales; //Lista con objetos que son reales, no imitacion
    uint256 globalIdentificator = 0; //Variable que usaremos para generar el id de los objetos
    uint numeroCompras = 0;
    uint deployDate;
    address trusted_manufacturer;

    struct Compra {
        Objeto _objeto;
        uint _identificadorObjeto; //Será la key del mapping de la lista compras
        uint _dateTransaction;
        uint _expireTimeWarranty;
    }

    constructor() {
        deployDate = block.timestamp; //Nos guardamos la hora a la que se ha iniciado la transacción
        trusted_manufacturer = msg.sender; //Guardamos el id del owner para restringir que solo el, pueda añadir productos a la cadena 
    }

    modifier onlyTrustedManufacturer() {
        require(msg.sender == trusted_manufacturer);
        _;
    }

    modifier checkDates(Objeto memory obj){
        require(block.timestamp >= obj._fechaIncorporacion);
        _;
    }

    //Comprueba si la garantia ha pasado
    function expiredTime(Compra memory compra_random) public view returns (bool) {
        return (block.timestamp >= compra_random._expireTimeWarranty);
    }

    //Funcion para añadir un objeto a la lista (Solo puede hacerlo el trusted manufacturer)
    function add_object(string memory _name, ProductStatus _status) public onlyTrustedManufacturer {
        globalIdentificator += 1;
        uint _id = newNFT();
        objetos_reales[globalIdentificator] = Objeto(_name, _id, block.timestamp, _status);
    }

    //Funcion para obtener un objeto de la lista objetos_reales
    function get_object_by_id(uint id) public view returns(Objeto memory, bool){
        for(uint idx = 0; idx < globalIdentificator; idx++){
            if(objetos_reales[idx]._identificador == id){
                return (objetos_reales[idx],true);
            }
        }
        return (objetos_reales[0],false);
    }
    
    //funcion para comprar un product
    function compra(Objeto memory _obj, uint _id) public checkDates(_obj){
        compras[numeroCompras] = Compra(_obj, _id, block.timestamp, block.timestamp + (2 * 365 days));
        numeroCompras += 1;
        super.changeOwner(tx.origin, _id);
        objStatusToSold(_id); //change to sold status
    }

    //funcion para comprobar si objeto es real
    function isObjReal(uint _id) public view returns(bool){
        Objeto memory obj;
        bool aux;
        (obj, aux) = get_object_by_id(_id);
        if (aux){
            return true;
        }else{
            return false;
        }
    }

    function objStatusToSold(uint id) internal{
        for(uint idx = 0; idx < globalIdentificator; idx++){
            if(objetos_reales[idx]._identificador == id){
                objetos_reales[idx].status = ProductStatus.Sold;
            }
        }
    }

    function getStatusOfObj(uint id) public view returns(ProductStatus status){
        for(uint idx = 0; idx < globalIdentificator; idx++){
            if(objetos_reales[idx]._identificador == id){
                return objetos_reales[idx].status;
            }
        }
    }
}