<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
        http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-3.8.xsd">

    <!-- ChangeSet for Folder table -->
    <changeSet id="20231001-1" author="developer">
        <createTable tableName="folder">
            <column name="id" type="BIGINT" autoIncrement="true">
                <constraints primaryKey="true"/>
            </column>
            <column name="name" type="VARCHAR(255)">
                <constraints nullable="false" unique="true"/>
            </column>
            <column name="parent_folder_id" type="BIGINT"/>
            <column name="creation_date" type="TIMESTAMP">
                <constraints nullable="false"/>
            </column>
            <column name="modification_date" type="TIMESTAMP">
                <constraints nullable="false"/>
            </column>
            <column name="created_by" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
            <column name="modified_by" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
        </createTable>

        <addForeignKeyConstraint
            baseTableName="folder"
            baseColumnNames="parent_folder_id"
            referencedTableName="folder"
            referencedColumnNames="id"
            constraintName="fk_folder_parent"/>
    </changeSet>

    <!-- ChangeSet for Document table -->
    <changeSet id="20231001-2" author="developer">
        <createTable tableName="document">
            <column name="id" type="BIGINT" autoIncrement="true">
                <constraints primaryKey="true"/>
            </column>
            <column name="name" type="VARCHAR(255)">
                <constraints nullable="false" unique="true"/>
            </column>
            <column name="description" type="VARCHAR(512)">
                <constraints nullable="false"/>
            </column>
            <column name="status" type="VARCHAR(50)">
                <constraints nullable="false"/>
            </column>
            <column name="folder_id" type="BIGINT"/>
            <column name="creation_date" type="TIMESTAMP">
                <constraints nullable="false"/>
            </column>
            <column name="modification_date" type="TIMESTAMP">
                <constraints nullable="false"/>
            </column>
            <column name="created_by" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
            <column name="modified_by" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
        </createTable>

        <addForeignKeyConstraint
            baseTableName="document"
            baseColumnNames="folder_id"
            referencedTableName="folder"
            referencedColumnNames="id"
            constraintName="fk_document_folder"/>
    </changeSet>

    <!-- ChangeSet for Metadata table -->
    <changeSet id="20231001-3" author="developer">
        <createTable tableName="metadata">
            <column name="id" type="BIGINT" autoIncrement="true">
                <constraints primaryKey="true"/>
            </column>
            <column name="document_id" type="BIGINT">
                <constraints nullable="false"/>
            </column>
            <column name="key" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
            <column name="value" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
        </createTable>

        <addForeignKeyConstraint
            baseTableName="metadata"
            baseColumnNames="document_id"
            referencedTableName="document"
            referencedColumnNames="id"
            constraintName="fk_metadata_document"/>
    </changeSet>

    <!-- ChangeSet for DocumentVersion table -->
    <changeSet id="20231001-4" author="developer">
        <createTable tableName="document_version">
            <column name="id" type="BIGINT" autoIncrement="true">
                <constraints primaryKey="true"/>
            </column>
            <column name="document_id" type="BIGINT">
                <constraints nullable="false"/>
            </column>
            <column name="version_number" type="INT">
                <constraints nullable="false"/>
            </column>
            <column name="name" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
            <column name="description" type="VARCHAR(512)">
                <constraints nullable="false"/>
            </column>
            <column name="creation_date" type="TIMESTAMP">
                <constraints nullable="false"/>
            </column>
            <column name="created_by" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
        </createTable>

        <addForeignKeyConstraint
            baseTableName="document_version"
            baseColumnNames="document_id"
            referencedTableName="document"
            referencedColumnNames="id"
            constraintName="fk_document_version_document"/>
    </changeSet>
</databaseChangeLog>
