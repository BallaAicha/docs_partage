Voici un use case claire de comment les projets sont codés ils sont divisés par module :

Créer un projet gradle :
Gradle.properties :
group
version
unibank.domain_version
unibank.platform_version=



Créer un premier module de ce genre :
Exemple : unibank-service-content-api
com.socgen.unibank.services.content.model

Exemple : 

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ContentEntry implements Domain {

    private URN urn;

    private String title;

    private String body;

    private String version;

    private ContentStatus status ;

    private ContentType type;

    private ContentFormat format;

    private String tags;

    private URN category;

    private URN space;
    
    private int order;
    
    private Date creationDate;
    
    private Date modificationDate;
    
    private AdminUser createdBy;
    
    private AdminUser modifiedBy;
    
    private Language language;

    public ContentEntry(URN urn, ContentType type, String title, String body, String version) {
        this.urn = urn;
        this.title = title;
        this.type = type;
        this.body = body;
        this.version = version;
    }

    @JsonIgnore
    public boolean isNotPublished() {
        return status != ContentStatus.PUBLISHED;
    }

}


import java.util.List;

public interface GetContentEntryList extends Query {

    List<ContentEntry> handle(GetContentEntryListRequest input, RequestContext context);

}


RequestMapping(name = "content", produces = "application/json")
public interface ContentAPI extends GetContentEntryList
    {

    @Operation(
        summary = "Fetch all content entries based on provided filter",
        parameters = {
            @Parameter(ref = "entityIdHeader", required = true),
            @Parameter(name = "type",  in = ParameterIn.QUERY, schema = @Schema(implementation = ContentType.class)),
            @Parameter(name = "count", in = ParameterIn.QUERY, schema = @Schema(type = "integer"))
        }
    )
    @GetMapping(path = "entries")
    @GraphQLQuery(name = "contentEntries")
    @RolesAllowed(Permissions.IS_GUEST)
    @Override
    List<ContentEntry> handle(GetContentEntryListRequest input, @GraphQLRootContext @ModelAttribute RequestContext ctx);


}

Un autre module appelé :
unibank-service-content-core

package com.socgen.unibank.services.content.core.usecases;
@Component
@AllArgsConstructor
public class GetContentEntryListImpl implements GetContentEntryList {

    private final ContentRepository contentRepository;

    @Override
    public List<ContentEntry> handle(GetContentEntryListRequest input, RequestContext context) {
       List<ContentEntry> entries;

            if (input != null && input.getType() != null){
                entries = contentRepository.findEntriesBy(input.getType(), Optional.ofNullable(input.getStatus()).orElse(ContentStatus.PUBLISHED),
                    Optional.ofNullable(input.getLanguage()).orElse(context.getUserLanguage()),
                    Optional.ofNullable(input.getCount()).orElse(100));
            }
            else{
                entries = contentRepository.findAllEntries();
            }

       return entries.stream().sorted(Comparator.comparingInt(ContentEntry::getOrder)).collect(Collectors.toList());
    }

}


@Entity
@Table(name = "content_entries")
@Data
public class EntryEntity {

    @EmbeddedId
    @AttributeOverride(name = "value", column = @Column(name = "id"))
    private URN id;

    private String version;

    private String title;

    private String tags;

    @Lob
    private String body;

    @Temporal(TemporalType.TIMESTAMP)
    private Date createdOn;

    private String createdBy;

    @Temporal(TemporalType.TIMESTAMP)
    private Date lastUpdatedOn;

    private String lastUpdatedBy;

    @Enumerated(EnumType.STRING)
    private ContentStatus status;

    @ManyToOne(cascade = CascadeType.ALL)
    @JoinColumn(name = "category")
    private CategoryEntity category;

    @Enumerated(EnumType.STRING)
    private ContentType type;

    @Enumerated(EnumType.STRING)
    private ContentFormat format;

    @Column(name = "position")
    private int order;

    @Enumerated(EnumType.STRING)
    private Language language;

    @AttributeOverride(name = "value", column = @Column(name = "space"))
    private URN space;

    public static EntryEntity from(ContentEntry domain) {
        EntryEntity entity = new EntryEntity();
        entity.setId(domain.getUrn());
        entity.setVersion(domain.getVersion());
        entity.setTitle(domain.getTitle());
        entity.setTags(domain.getTags());
        entity.setBody(domain.getBody());
        entity.setCreatedOn(domain.getCreationDate());
        entity.setLastUpdatedOn(domain.getModificationDate());
        entity.setLastUpdatedBy(domain.getModifiedBy().getEmail());
        entity.setCreatedBy(domain.getCreatedBy().getEmail());
        entity.setStatus(domain.getStatus());
        if(domain.getCategory()!=null) {
            CategoryEntity categoryEntity = new CategoryEntity();
            categoryEntity.setId(domain.getCategory());
            entity.setCategory(categoryEntity);
        }
        entity.setType(domain.getType());
        entity.setFormat(domain.getFormat() != null ? domain.getFormat() : ContentFormat.TEXT);
        entity.setOrder(domain.getOrder());
        entity.setLanguage(domain.getLanguage());
        entity.setSpace(domain.getSpace());
        return entity;
    }

    public ContentEntry toDomain() {
        ContentSpace contentSpace = new ContentSpace();
        ContentEntry contentEntry = new ContentEntry();
        contentEntry.setUrn(id);
        contentEntry.setVersion(version);
        contentEntry.setTitle(title);
        contentEntry.setBody(body);
        contentEntry.setTags(tags);
        contentEntry.setCreationDate(createdOn);
        contentEntry.setModifiedBy(new AdminUser(lastUpdatedBy));
        contentEntry.setCreatedBy(new AdminUser(createdBy));
        contentEntry.setModificationDate(lastUpdatedOn);
        contentEntry.setStatus(status);
        contentEntry.setSpace(contentSpace.getUrn());
        if(category!=null) {
            contentEntry.setCategory(category.getId());
        }
        contentEntry.setType(type);
        contentEntry.setFormat(format);
        contentEntry.setOrder(order);
        contentEntry.setLanguage(language);
        return contentEntry;
    }


}
@Component
public interface EntryJpaRepo extends JpaRepository<EntryEntity, URN> {

    long countByType(ContentType type);

    List<EntryEntity> findByTypeAndStatusOrderByCreatedOnDesc(ContentType type, ContentStatus status, Pageable pageable);
    
    List<EntryEntity> findByTypeAndStatusAndLanguageOrderByCreatedOnDesc(ContentType type, ContentStatus status, Language language, Pageable pageable);

    void deleteByTypeAndLanguage(ContentType type,Language language);

    @Modifying
    @Query("update EntryEntity e set e.status ='ARCHIVED' where e.type = :contentType  and e.language = :language")
    void archiveEntry( @Param("language")Language language, @Param("contentType") ContentType contentType);

}


@Component
@AllArgsConstructor
public class ContentRepoImpl implements ContentRepository {

    private EntryJpaRepo entries;
    private  CategoryJpaRepo categories;
    private  SpaceJpaRepo spaces;


    @Override
    public ContentSpace saveSpace(ContentSpace value) {
        SpaceEntity entity = SpaceEntity.from(value);
        spaces.save(entity);
        return entity.toDomain();
    }


    @Override
    public void deleteEntryByTypeAndLanguage(ContentType type, Language language) {
        entries.deleteByTypeAndLanguage(type,language);
    }

    @Override
    public void saveContentEntries(List<ContentEntry> entries) {
        List<EntryEntity> entities = entries.stream().map(EntryEntity::from).collect(Collectors.toList());
        this.entries.saveAll(entities);
    }


    @Override
    @Transactional(readOnly = true)
    public List<ContentEntry> findAllEntries() {
        List<EntryEntity> entities = entries.findAll();
        return entities.stream().map(EntryEntity::toDomain).collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<ContentEntry> findEntriesBy(ContentType type, ContentStatus status, Language language, int count) {
        List<EntryEntity> entities = entries.findByTypeAndStatusAndLanguageOrderByCreatedOnDesc(type, status, language, PageRequest.of(0, count));
        return entities.stream().map(EntryEntity::toDomain).collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void archiveEntry(ContentType contentType,Language language) {
        entries.archiveEntry(language,contentType);
    }





}

Un autre module :: unibank-service-content
package com.socgen.unibank.services.content.gateways.inbound;


import com.socgen.unibank.platform.models.OpenAPIRefs;
import com.socgen.unibank.platform.springboot.config.web.GraphQLController;
import com.socgen.unibank.services.content.ContentAPI;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.web.bind.annotation.RestController;

@GraphQLController
@RestController
@SecurityRequirement(name = OpenAPIRefs.OAUTH2)
@SecurityRequirement(name = OpenAPIRefs.JWT)
public interface ContentEndpoint extends ContentAPI {
}
@Configuration
public class ContentBeansFactory {

    @Bean
    ProxyEndpoints createContentAPIEndpoints() {
        return ProxyEndpoints.create(ContentEndpoint.class);
    }



}

