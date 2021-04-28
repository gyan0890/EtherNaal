// var axios = require('axios');
// var data = JSON.stringify(
//     {"name":"TestNFT",
//     "description":"Test NFT",
//     "image":"ipfs://ipfs/QmQLJBPeiwbiKpmvaQrv2ru1vHY3gmUb2DadjdXbUC3ZZD/image1.jpg",
//     "external_url":"https://app.rarible.com/0x60f80121c31a0d46b5279700f9df786054aa5ee5:123913",
//     // "artist_url": "an ENS URL pointing to the artists site",
//     // "artist_years_of_experience": 4,
//     // "artist_location": "London",
//     "attributes":[
//         {"key":"Test",
//         "trait_type":"Test",
//         "value":"Test"}
//     ]
// });

// var config = {
//   method: 'post',
//   url: 'https://api.pinata.cloud/pinning/pinFileToIPFS',
//   headers: { 
//     'pinata_api_key': 'b7c2feaad1b9f334121f',// KEY_HERE, 
//     'pinata_secret_api_key': 'c78c21e894412085804708db7978fa89f2469abad803c444ca17641c13cb947b',// SECRET_KEY_HERE, 
//     'Content-Type': 'application/json'
//   },
//   data: data
// };

// axios(config).then(function (response) {
//   console.log(JSON.stringify(response.data));
// }).catch(function (error) {
//   console.log(error);
// });


// ----------

const axios = require('axios');

const client = axios.create({
    baseURL: "https://api-staging.rarible.com/"
})
var creator_wallet_address = "0x..";
var tokenId = await getNonce("0x25646B08D9796CedA5FB8CE0105a51820740C049", creator_wallet_address);
var data = JSON.stringify(
    {
        "name":"TestNFT",
        "description":"Test NFT",
        "image":"ipfs://ipfs/QmQLJBPeiwbiKpmvaQrv2ru1vHY3gmUb2DadjdXbUC3ZZD/image1.jpg",
        "external_url":"https://app.rarible.com/"+creator_wallet_address+":"+tokenId,
        "artist_url": "an ENS URL pointing to the artists site",
        "artist_years_of_experience": 4,
        "artist_location": "London",
        "attributes":[
            {
                "key":"Test",
                "trait_type":"Test",
                "value":"Test"
            }
    ]
});

pinJSONToIPFS = (pinataApiKey, pinataSecretApiKey, JSONBody) => {
    const url = `https://api.pinata.cloud/pinning/pinJSONToIPFS`;
    return axios
        .post(url, data, {
            headers: {
                pinata_api_key: pinataApiKey,
                pinata_secret_api_key: pinataSecretApiKey
            }
        })
        .then(function (response) {
            console.log(response);
        })
        .catch(function (error) {
            console.log(error);
        });
};

async function getNonce(token, minter) 
{   const res = await client.get("protocol/ethereum/nft/indexer/v0.1/collections/${token}/generate_token_id?minter=${minter}");
    return res.data.tokenId;
}

pinJSONToIPFS('b7c2feaad1b9f334121f', 'c78c21e894412085804708db7978fa89f2469abad803c444ca17641c13cb947b');