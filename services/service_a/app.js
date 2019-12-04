const express = require('express');
const bodyParser = require('body-parser');
const fetch = require("node-fetch")
const app = express();
app.use(bodyParser.json());

const port = process.env.PORT || 3000;
const sidecarUrl = process.env.SIDECAR_URL || "http://localhost:3001";
const up = new Date().toUTCString()

app.get('/health', (req, res) => res.send("Up at " + up))

app.get('/hello_a', (req, res) => {
    console.log(sidecarUrl)
    fetch(sidecarUrl + "/hello_b")
        .then(r => r.json())
        .then(data => res.send(Object.assign(data, {message_a:"service_a up at " + up})))
        .catch(e => {console.log(e); res.sendStatus(500); })
});

app.listen(port, () => console.log(`Node App serviceA listening on port ${port}`));