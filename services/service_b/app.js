const express = require('express');
const bodyParser = require('body-parser');
const fetch = require("node-fetch")
const app = express();
app.use(bodyParser.json());

const port = process.env.PORT || 3001;
const id = process.env.APP_ID || "1";
const up = new Date().toUTCString()

app.get('/health', (req, res) => res.send("Up at " + up))

app.get('/hello_b', (req, res) => {
    res.send({"message_b":`service_b(${id}) up at ${up}`})
});

app.listen(port, () => console.log(`Node App service_b(${id}) listening on port ${port}`));