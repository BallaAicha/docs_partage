il faut savoir que toute la logique de S3 est déjà géré par mon entreprise j'ai juste besoin d'injecter S3Client et d'appeler la méthode que j'ai besoin 
injecte ceci ::  S3Client et appelle la méthode upload toi tu géres aucune logique S3 , tu l'injecte et tu l'utilise tout est déjà géré :

y'à toute ces méthodes disponibles sur le S3 client ::
@Override
	public void upload(InputStream source, String objectName, String contentType) {
		upload(source, defaultBucketName, objectName, contentType);
	}

	@SneakyThrows
	@Override
	public void upload(InputStream source, String bucket, String objectName, String contentType) {
		try {
			ObjectMetadata metadata = new ObjectMetadata();
			metadata.setContentEncoding(StandardCharsets.UTF_8.name());
			metadata.setContentType(contentType);
			client.putObject(bucket, objectName, source, metadata);
		} catch (Exception e) {
			throw new TechnicalException("S3_UPLOAD_ERROR", e);
		}
	}

	@Override
	public void upload(File source, String objectName) {
		upload(source, defaultBucketName, objectName);
	}

	@SneakyThrows
	@Override
	public void upload(File source, String bucket, String objectName) {
		try {
			client.putObject(bucket, objectName, source);
		} catch (Exception e) {
			throw new TechnicalException("S3_UPLOAD_ERROR", e);
		}
	}

regarde le mieux adapté et tu l'apppelle en lui passant les bons paramétres 
